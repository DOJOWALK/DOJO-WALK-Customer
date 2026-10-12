
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

  String get _dogName =>
      (widget.dogDetails['name'] ??
              widget.dogDetails['petName'] ??
              '')
          .toString()
          .trim();

  String get _dogId =>
      (widget.dogDetails['dogId'] ?? '').toString().trim();

  String get _dogBreed =>
      (widget.dogDetails['breed'] ?? 'Not provided').toString();

  String get _dogGender =>
      (widget.dogDetails['gender'] ?? 'Not provided').toString();

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
        'time': widget.schedule['time'] ?? '',
        'duration': widget.schedule['duration'] ?? 30,
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
    final configured = walk['price'];
    if (configured is num) return configured.toInt();

    // Only the configured 30-minute rate is known.
    if (_duration(walk) == 30) return 149;
    return null;
  }

  int? get _dailyPrice {
    final prices = _walks.map(_price).toList();
    if (prices.isEmpty || prices.any((price) => price == null)) {
      return null;
    }
    return prices.fold<int>(0, (sum, price) => sum + price!);
  }

  String get _addressId =>
      (widget.pickupAddress['addressId'] ??
              widget.pickupAddress['pickupAddressId'] ??
              '')
          .toString()
          .trim();

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

  DateTime? _selectedDate() {
    final raw = widget.schedule['date'] ??
        widget.schedule['selectedDate'];

    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;

    if (raw != null) {
      final value = raw.toString().trim();

      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;

      // Supports dd/MM/yyyy from the schedule screen.
      final match =
          RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$')
              .firstMatch(value);
      if (match != null) {
        return DateTime(
          int.parse(match.group(3)!),
          int.parse(match.group(2)!),
          int.parse(match.group(1)!),
        );
      }
    }

    return null;
  }

  String _formatDate() {
    final date = _selectedDate();
    if (date == null) return 'Not selected';

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

    if (match == null) return value.isEmpty ? 'Not selected' : value;

    var hour = int.parse(match.group(1)!);
    final minute = match.group(2) ?? '00';
    var period = match.group(3)?.toUpperCase();

    if (period == null) {
      period = hour >= 12 ? 'PM' : 'AM';
      hour %= 12;
      if (hour == 0) hour = 12;
    }

    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  String get _planName =>
      _isRegular ? 'Regular Daily Walk' : 'One-Time Walk';

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting || _submitted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Booking submit karne ke liye pehle login karein.');
      return;
    }

    if (_dogId.isEmpty || _dogName.isEmpty) {
      _message('Please apna saved dog select karein.');
      return;
    }

    if (_addressId.isEmpty || _addressText().isEmpty) {
      _message('Please valid pickup address select karein.');
      return;
    }

    if (_walks.isEmpty) {
      _message('Please walk ka time select karein.');
      return;
    }

    final date = _selectedDate();
    if (date == null) {
      _message('Please walk ki date select karein.');
      return;
    }

    for (final walk in _walks) {
      final time = (walk['time'] ?? '').toString().trim();
      if (time.isEmpty || _duration(walk) <= 0) {
        _message('Har walk ka valid time aur duration select karein.');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Recheck that the selected dog still exists.
      final petDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(_dogId)
          .get();

      if (!petDoc.exists) {
        throw StateError(
          'Selected dog ab saved list mein nahi hai. Dobara select karein.',
        );
      }

      final savedDog = petDoc.data() ?? <String, dynamic>{};
      final dogName = (savedDog['name'] ??
              savedDog['petName'] ??
              _dogName)
          .toString()
          .trim();

      if (dogName.isEmpty) {
        throw StateError('Dog ka naam available nahi hai.');
      }

      final bookingRef = firestore.collection('bookings').doc();
      final firstWalk = _walks.first;
      final selectedDate = DateTime(date.year, date.month, date.day);

      final pickup = <String, dynamic>{
        ...widget.pickupAddress,
        'address': _addressText(),
      };

      // Keep only the fields accepted by the current booking rules.
      final bookingData = <String, dynamic>{
        'bookingId': bookingRef.id,
        'customerId': user.uid,
        'walkType': 'scheduled',
        'bookingPlan': _isRegular ? 'regular' : 'one_time',
        'serviceType': _isRegular ? 'regular_walk' : 'temporary_walk',
        'serviceName': _planName,
        'petName': dogName,
        'dogId': _dogId,
        'petDetails': {
          ...savedDog,
          'dogId': _dogId,
          'name': dogName,
          'breed': savedDog['breed'] ?? _dogBreed,
          'gender': savedDog['gender'] ?? _dogGender,
        },
        'pickupAddressId': _addressId,
        'pickupAddress': pickup,
        'scheduledAt': Timestamp.fromDate(selectedDate),
        'duration': '${_duration(firstWalk)} minutes',
        'preferredTime': firstWalk['time'].toString(),
        'status': 'pending',
        'walkerId': null,
        'cancelRequest': null,
        'createdAt': FieldValue.serverTimestamp(),
        if (_isRegular) 'frequency': 'Daily',
        if (_isRegular) 'walksPerWeek': 7,
      };

      // Do not write to walk_requests from the customer app:
      // the current Firestore rules deny client writes there.
      await bookingRef.set(bookingData);

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
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _message(e.message);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _message(
        e.code == 'permission-denied'
            ? 'Booking save nahi hui. Firebase Rules aur required user fields check karne honge.'
            : 'Booking save nahi hui. Please dobara try karein.',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail('Name', _dogName),
                  _detail('Breed', _dogBreed),
                  _detail('Gender', _dogGender),
                  if (widget.dogDetails['age'] != null)
                    _detail('Age', '${widget.dogDetails['age']}'),
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
                  _detail('Plan', _planName),
                  _detail('Start date', _formatDate()),
                  if (_isRegular)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Daily, Monday to Sunday',
                        style: TextStyle(color: confirmationMuted),
                      ),
                    ),
                  ..._walks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final walk = entry.value;
                    final price = _price(walk);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.schedule,
                        color: confirmationOrange,
                      ),
                      title: Text('Walk ${index + 1}'),
                      subtitle: Text(
                        '${_formatTime('${walk['time'] ?? ''}')} · '
                        '${_duration(walk)} minutes',
                      ),
                      trailing: Text(
                        price == null ? 'Price pending' : '₹$price',
                        style: const TextStyle(
                          color: confirmationOrange,
                          fontWeight: FontWeight.bold,
                        ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dailyPrice == null
                        ? 'Selected walk price needs confirmation.'
                        : 'Estimated selected-walk total: ₹$_dailyPrice',
                    style: const TextStyle(
                      color: confirmationText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isRegular)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Regular plan ka final weekly/monthly amount confirmation ke baad bataya jayega.',
                        style: TextStyle(color: confirmationMuted),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Final price booking confirmation se pehle confirm hoga.',
                    style: TextStyle(
                      color: confirmationMuted,
                      fontSize: 12,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
              ),
              child: const Text('Go Back & Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
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
}
