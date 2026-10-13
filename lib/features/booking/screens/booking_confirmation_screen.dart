
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'choose_walk_screen.dart';

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

  bool get _isOneTime =>
      widget.walkType == WalkBookingType.oneTime && !_isRegular;

  bool get _isChooseDates =>
      widget.walkType == WalkBookingType.chooseDates && !_isRegular;

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

    // Existing configured fallback: 30-minute walk.
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
    final raw =
        widget.schedule['date'] ?? widget.schedule['selectedDate'];

    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;

    if (raw != null) {
      final value = raw.toString().trim();

      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;

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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(String raw) {
    final value = raw.trim();

    final match = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(value);

    if (match == null) {
      return value.isEmpty ? 'Not selected' : value;
    }

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

  /// Converts a displayed time such as "7:00 AM" into a DateTime.
  DateTime? _dateTimeForWalk(DateTime date, String rawTime) {
    final match = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(rawTime.trim());

    if (match == null) return null;

    final displayedHour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '00');
    final period = match.group(3)!.toUpperCase();

    if (displayedHour == null ||
        minute == null ||
        displayedHour < 1 ||
        displayedHour > 12 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    var hour = displayedHour % 12;

    if (period == 'PM') {
      hour += 12;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  String get _planName {
    if (_isRegular) return 'Regular Daily Walk';
    if (_isChooseDates) return 'Customize Walk';
    return 'One-Time Walk';
  }

  String get _bookingPlan {
    if (_isRegular) return 'regular';
    if (_isChooseDates) return 'customize';
    return 'one_time';
  }

  String get _serviceType {
    if (_isRegular) return 'regular_walk';
    if (_isChooseDates) return 'custom_walk';
    return 'temporary_walk';
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateSchedule(DateTime date, List<Map<String, dynamic>> walks) {
    if (walks.isEmpty) {
      return 'Please walk ka time select karein.';
    }

    if (_isOneTime && walks.length != 1) {
      return 'One-Time Plan mein sirf ek walk select karein.';
    }

    if ((_isRegular || _isChooseDates) &&
        (walks.length < 1 || walks.length > 3)) {
      return 'Ek din mein 1 se 3 walks select karein.';
    }

    final now = DateTime.now();

    for (final walk in walks) {
      final rawTime = (walk['time'] ?? '').toString().trim();
      final duration = _duration(walk);

      if (rawTime.isEmpty || duration <= 0) {
        return 'Har walk ka valid time aur duration select karein.';
      }

      final scheduledAt = _dateTimeForWalk(date, rawTime);

      if (scheduledAt == null) {
        return 'Walk ka time sahi format mein nahi hai. Time dobara select karein.';
      }

      if (!scheduledAt.isAfter(now)) {
        return 'Walk ka time beet chuka hai. Future ka time select karein.';
      }
    }

    // Prevent selected walks from overlapping each other.
    final sortedWalks = [...walks];

    sortedWalks.sort((a, b) {
      final timeA = _dateTimeForWalk(date, '${a['time'] ?? ''}');
      final timeB = _dateTimeForWalk(date, '${b['time'] ?? ''}');

      if (timeA == null || timeB == null) return 0;
      return timeA.compareTo(timeB);
    });

    for (var i = 0; i < sortedWalks.length - 1; i++) {
      final first = sortedWalks[i];
      final second = sortedWalks[i + 1];

      final firstStart =
          _dateTimeForWalk(date, '${first['time'] ?? ''}');
      final secondStart =
          _dateTimeForWalk(date, '${second['time'] ?? ''}');

      if (firstStart == null || secondStart == null) {
        return 'Walk ka time dobara select karein.';
      }

      final firstEnd =
          firstStart.add(Duration(minutes: _duration(first)));

      if (secondStart.isBefore(firstEnd)) {
        return 'Do walks ka time overlap ho raha hai. Time change karein.';
      }
    }

    return null;
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

    final walks = _walks;
    final date = _selectedDate();

    if (date == null) {
      _message('Please walk ki date select karein.');
      return;
    }

    // Validate again at submission time because time may have passed
    // while the customer was reviewing the booking.
    final scheduleError = _validateSchedule(date, walks);

    if (scheduleError != null) {
      _message(scheduleError);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Verify that the selected dog still exists in the customer's account.
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

      // Check once more after the network request.
      final finalScheduleError = _validateSchedule(date, walks);

      if (finalScheduleError != null) {
        throw StateError(finalScheduleError);
      }

      final bookingRef = firestore.collection('bookings').doc();

      final selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final firstWalk = walks.first;

      final pickup = <String, dynamic>{
        ...widget.pickupAddress,
        'address': _addressText(),
      };

      final walkSchedules = walks.asMap().entries.map((entry) {
        final index = entry.key;
        final walk = entry.value;
        final walkTime = (walk['time'] ?? '').toString().trim();
        final walkStart = _dateTimeForWalk(date, walkTime);

        return <String, dynamic>{
          'walkNumber': index + 1,
          'time': walkTime,
          'startHour': walkStart?.hour,
          'startMinute': walkStart?.minute,
          'duration': _duration(walk),
          if (_price(walk) != null) 'price': _price(walk),
        };
      }).toList();

      final bookingData = <String, dynamic>{
        'bookingId': bookingRef.id,
        'customerId': user.uid,
        'walkType': 'scheduled',
        'bookingPlan': _bookingPlan,
        'serviceType': _serviceType,
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

        // Compatibility fields for existing booking screens.
        // These describe the first walk.
        'duration': '${_duration(firstWalk)} minutes',
        'preferredTime': firstWalk['time'].toString(),

        // Save all selected walks for every booking plan.
        'walkCount': walks.length,
        'walkSchedules': walkSchedules,

        'status': 'pending',
        'walkerId': null,
        'cancelRequest': null,
        'createdAt': FieldValue.serverTimestamp(),

        if (_isRegular) ...{
          'frequency': 'daily',
          'walksPerWeek': 7,
          'walksPerDay': walks.length,
          'planStatus': 'active',
        },

        if (_isChooseDates) ...{
          'walksPerDay': walks.length,
        },
      };

      // Write one booking document.
      // Do not create walk_requests here because the current Firebase
      // rules deny client writes to that collection.
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
                Navigator.of(context)
                    .popUntil((route) => route.isFirst);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);
      _message(e.message.toString());
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      _message(
        e.code == 'permission-denied'
            ? 'Booking rejected by Firebase Rules. Check the booking fields and Rules.'
            : 'Booking save nahi hui (${e.code}). Please dobara try karein.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);
      _message('Booking save nahi hui: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = _addressText();
    final total = _dailyPrice;

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
                        'Daily plan: Monday to Sunday, continuously. '
                        'No automatic 7-day expiry.',
                        style: TextStyle(
                          color: confirmationMuted,
                          height: 1.4,
                        ),
                      ),
                    ),

                  if (_isChooseDates)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Customized schedule for the selected date.',
                        style: TextStyle(
                          color: confirmationMuted,
                        ),
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
                    total == null
                        ? 'Selected walk price needs confirmation.'
                        : _isRegular
                            ? 'Estimated total per day: ₹$total'
                            : 'Estimated selected-walk total: ₹$total',
                    style: const TextStyle(
                      color: confirmationText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (_isRegular)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Regular plan ka final weekly/monthly amount '
                        'confirmation ke baad bataya jayega.',
                        style: TextStyle(
                          color: confirmationMuted,
                        ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
                side: const BorderSide(
                  color: confirmationOrange,
                ),
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
        border: Border.all(
          color: const Color(0xFFF0E2D5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: confirmationOrange,
                size: 24,
              ),
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
              style: const TextStyle(
                color: confirmationMuted,
              ),
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
