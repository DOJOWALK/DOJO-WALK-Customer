
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_start_screen.dart';

const Color confirmationOrange = Color(0xFFFF7900);
const Color confirmationBackground = Color(0xFFFFFAF5);
const Color confirmationText = Color(0xFF202020);
const Color confirmationMuted = Color(0xFF777777);

class BookingConfirmationScreen extends StatefulWidget {
  final WalkBookingType walkType;
  final Map<String, dynamic> dogDetails;
  final Map<String, dynamic> pickupAddress;
  final Map<String, dynamic> schedule;

  const BookingConfirmationScreen({
    super.key,
    required this.walkType,
    required this.dogDetails,
    required this.pickupAddress,
    required this.schedule,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends State<BookingConfirmationScreen> {
  bool _isSubmitting = false;
  bool _submitted = false;

  bool get _isRegular =>
      widget.walkType == WalkBookingType.regular ||
      widget.schedule['isRegular'] == true;

  List<Map<String, dynamic>> get _walks {
    final raw = widget.schedule['walks'];

    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [
      {
        'time': widget.schedule['time'] ?? 'Not selected',
        'duration': widget.schedule['duration'] ?? 30,
        'price': widget.schedule['price'],
      }
    ];
  }

  int _duration(Map<String, dynamic> walk) {
    final value = walk['duration'];
    if (value is num) return value.toInt();

    final match = RegExp(r'\d+').firstMatch('$value');
    return match == null ? 30 : int.parse(match.group(0)!);
  }

  int? _price(Map<String, dynamic> walk) {
    final value = walk['price'];
    if (value is num) return value.toInt();

    // Draft rate for a 30-minute walk.
    if (_duration(walk) == 30) return 149;

    return null;
  }

  int get _dailyPrice {
    final configured = widget.schedule['dailyPrice'];
    if (configured is num) return configured.toInt();

    final prices = _walks.map(_price).toList();
    if (prices.any((price) => price == null)) return 0;

    return prices.fold<int>(0, (sum, price) => sum + price!);
  }

  String get _dogName =>
      (widget.dogDetails['name'] ??
              widget.dogDetails['petName'] ??
              'Your Dog')
          .toString();

  String get _dogBreed =>
      (widget.dogDetails['breed'] ?? 'Not provided').toString();

  String get _dogAge {
    final value = widget.dogDetails['age'] ??
        widget.dogDetails['ageYears'] ??
        widget.dogDetails['dob'];
    return value?.toString() ?? 'Not provided';
  }

  String get _dogGender =>
      (widget.dogDetails['gender'] ?? 'Not provided').toString();

  String _formatDate() {
    final raw =
        widget.schedule['selectedDate'] ?? widget.schedule['date'];

    if (raw == null) return 'Not selected';

    DateTime? date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else {
      date = DateTime.tryParse(raw.toString());
    }

    if (date == null) return raw.toString();

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(String raw) {
    final value = raw.trim();
    final match = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value);

    if (match == null) return value;

    var hour = int.parse(match.group(1)!);
    final minute = match.group(2) ?? '00';
    var period = match.group(3)?.toUpperCase();

    if (period == null) {
      period = hour >= 12 ? 'PM' : 'AM';
      hour %= 12;
      if (hour == 0) hour = 12;
    }

    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  String _addressText() {
    final parts = <String>[];

    for (final key in [
      'flatHouse',
      'buildingSociety',
      'address',
      'area',
      'landmark',
      'city',
      'pincode',
    ]) {
      final value = widget.pickupAddress[key]?.toString().trim();
      if (value != null &&
          value.isNotEmpty &&
          !parts.contains(value)) {
        parts.add(value);
      }
    }

    return parts.join(', ');
  }

  String _walkTypeName() {
    if (_isRegular) return 'Regular Daily Walk';
    if (widget.walkType == WalkBookingType.chooseDates) {
      return 'Choose Dates Walk';
    }
    return 'One-Time Walk';
  }

  Map<String, dynamic> _petDetails() {
    return {
      ...widget.dogDetails,
      'dogId': widget.dogDetails['dogId'],
      'name': _dogName,
      'breed': _dogBreed,
      'gender': _dogGender,
    };
  }

  List<Map<String, dynamic>> _savedWalks() {
    return _walks.map((walk) {
      return {
        ...walk,
        'time': walk['time']?.toString() ?? 'Not selected',
        'duration': _duration(walk),
        'price': _price(walk),
      };
    }).toList();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting || _submitted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Booking submit karne ke liye pehle login karein.');
      return;
    }

    final dogId = widget.dogDetails['dogId']?.toString() ?? '';
    if (dogId.isEmpty || _dogName == 'Your Dog') {
      _message('Please apne dog ki saved details select karein.');
      return;
    }

    final address = _addressText();
    if (address.isEmpty) {
      _message('Please pickup address select karein.');
      return;
    }

    if (_walks.isEmpty) {
      _message('Please walk ka time select karein.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final bookingRef = firestore.collection('bookings').doc();
      final requestRef = firestore.collection('walk_requests').doc();

      final now = DateTime.now();
      final rawDate =
          widget.schedule['selectedDate'] ?? widget.schedule['date'];

      DateTime selectedDate = now;
      if (rawDate is Timestamp) {
        selectedDate = rawDate.toDate();
      } else if (rawDate != null) {
        selectedDate = DateTime.tryParse(rawDate.toString()) ?? now;
      }

      final firstWalk = _walks.first;
      final savedWalks = _savedWalks();

      final pickup = <String, dynamic>{
        ...widget.pickupAddress,
        'address': address,
      };

      final totalDuration =
          _walks.fold<int>(0, (sum, walk) => sum + _duration(walk));

      final bookingData = <String, dynamic>{
        'bookingId': bookingRef.id,
        'customerId': user.uid,
        'walkType': 'scheduled',
        'bookingPlan': _isRegular ? 'regular' : 'one_time',
        'serviceType':
            _isRegular ? 'regular_walk' : 'temporary_walk',
        'serviceName': _walkTypeName(),
        'petName': _dogName,
        'dogId': dogId,
        'petDetails': _petDetails(),
        'pickupAddressId':
            widget.pickupAddress['addressId'] ?? '',
        'pickupAddress': pickup,
        'scheduledAt': Timestamp.fromDate(selectedDate),
        'scheduleDate': Timestamp.fromDate(selectedDate),
        'duration': _duration(firstWalk),
        'preferredTime':
            firstWalk['time']?.toString() ?? 'Not selected',
        'walks': savedWalks,
        'walkCount': _walks.length,
        'totalDurationMinutes': totalDuration,
        'dailyPrice': _dailyPrice,
        'weeklyPrice': _isRegular ? _dailyPrice * 7 : _dailyPrice,
        'monthlyPrice': _isRegular ? _dailyPrice * 30 : _dailyPrice,
        'frequency': _isRegular
            ? (widget.schedule['frequency'] ?? 'Daily')
            : null,
        'walksPerWeek': _isRegular ? 7 : null,
        'includesSunday': _isRegular,
        'walkerId': null,
        'status': 'pending',
        'paymentStatus': 'pending',
        'paymentId': null,
        'cancelRequest': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final requestData = <String, dynamic>{
        'bookingId': bookingRef.id,
        'customerId': user.uid,
        'dogId': dogId,
        'petName': _dogName,
        'serviceType':
            _isRegular ? 'regular_walk' : 'temporary_walk',
        'pickupAddress': pickup,
        'walks': savedWalks,
        'status': 'pending',
        'walkerId': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();
      batch.set(bookingRef, bookingData);
      batch.set(requestRef, requestData);
      await batch.commit();

      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.check_circle,
            color: Color(0xFF218838),
            size: 54,
          ),
          title: const Text(
            'Request Received!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: confirmationText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Hum jald hi aapki booking confirm karenge.',
            textAlign: TextAlign.center,
            style: TextStyle(color: confirmationMuted),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: confirmationOrange,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _message(
        e.code == 'permission-denied'
            ? 'Booking save nahi ho saki. Firebase permissions check karein.'
            : 'Booking save nahi ho saki. Please dobara try karein.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _message('Kuch galat hua. Please dobara try karein.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = _addressText();

    return Scaffold(
      backgroundColor: confirmationBackground,
      appBar: AppBar(
        backgroundColor: confirmationOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Review Your Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              icon: Icons.pets,
              title: 'Your Dog',
              trailing: _editLabel(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail('Name', _dogName),
                  _detail('Breed', _dogBreed),
                  _detail('Age', _dogAge),
                  _detail('Gender', _dogGender),
                  if ((widget.dogDetails['specialCare'] ??
                          widget.dogDetails['specialCareInstructions']) !=
                      null)
                    _detail(
                      'Special care',
                      '${widget.dogDetails['specialCare'] ?? widget.dogDetails['specialCareInstructions']}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.calendar_month,
              title: 'Walk Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail('Plan', _walkTypeName()),
                  _detail('Date', _formatDate()),
                  if (_isRegular)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Every day, Monday to Sunday',
                        style: TextStyle(
                          color: confirmationMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ..._walks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final walk = entry.value;
                    final price = _price(walk);
                    final time = walk['time']?.toString() ??
                        'Not selected';

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: confirmationBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0E2D5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            index == 0
                                ? Icons.wb_sunny_outlined
                                : Icons.schedule,
                            color: confirmationOrange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Walk ${index + 1}',
                                  style: const TextStyle(
                                    color: confirmationText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(time),
                                  style: const TextStyle(
                                    color: confirmationMuted,
                                  ),
                                ),
                                Text(
                                  '${_duration(walk)} minutes',
                                  style: const TextStyle(
                                    color: confirmationMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            price == null ? 'Price pending' : '₹$price',
                            style: const TextStyle(
                              color: confirmationOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.location_on_outlined,
              title: 'Pickup Location',
              trailing: _editLabel(),
              child: Text(
                address.isEmpty ? 'Address not available' : address,
                style: const TextStyle(
                  color: confirmationMuted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.receipt_long,
              title: 'Price Summary',
              child: Column(
                children: [
                  _priceRow(
                    'Per day · ${_walks.length} walk(s)',
                    _dailyPrice,
                  ),
                  if (_isRegular) ...[
                    const SizedBox(height: 12),
                    _priceRow('Per week · 7 days', _dailyPrice * 7),
                    const SizedBox(height: 12),
                    _priceRow('30 days', _dailyPrice * 30, bold: true),
                  ],
                  const SizedBox(height: 10),
                  const Text(
                    'Final amount is based on the selected walks and configured pricing.',
                    style: TextStyle(
                      color: confirmationMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0E2D5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF218838),
                    size: 25,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to Submit',
                          style: TextStyle(
                            color: confirmationText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please apni booking details check kar lein.',
                          style: TextStyle(color: confirmationMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    _isSubmitting || _submitted ? null : _submitBooking,
                style: FilledButton.styleFrom(
                  backgroundColor: confirmationOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFFC28F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : _submitted
                          ? 'Request Submitted'
                          : 'Submit Booking Request',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: confirmationOrange,
                side: const BorderSide(color: confirmationOrange),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Go Back & Edit'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: confirmationOrange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: confirmationText,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(color: confirmationMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: confirmationText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    int amount, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: confirmationText,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '₹$amount',
          style: TextStyle(
            color: confirmationOrange,
            fontSize: bold ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _editLabel() {
    return const Text(
      'Edit',
      style: TextStyle(
        color: confirmationOrange,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
