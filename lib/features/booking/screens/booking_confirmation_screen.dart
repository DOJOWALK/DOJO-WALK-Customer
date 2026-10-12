
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_start_screen.dart';

const Color confirmationOrange = Color(0xFFFF7900);
const Color confirmationBackground = Color(0xFFFFFAF5);
const Color confirmationText = Color(0xFF202020);

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.walkType,
    required this.dogDetails,
    required this.pickupAddress,
    required this.schedule,
  });

  final WalkBookingType walkType;
  final Map<String, dynamic> dogDetails;
  final Map<String, dynamic> pickupAddress;
  final Map<String, dynamic> schedule;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends State<BookingConfirmationScreen> {
  bool _isSubmitting = false;

  bool get _isRegular => widget.walkType == WalkBookingType.regular;

  String get _walkTypeLabel =>
      _isRegular ? 'Regular Walks' : 'One-Time Walk';

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }
    return value.toString();
  }

  bool _hasValue(dynamic value) =>
      value != null && value.toString().trim().isNotEmpty;

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  String _ageLabel(dynamic age) {
    if (!_hasValue(age)) return 'Not provided';

    final value = age.toString().trim();

    // New records already contain labels such as "2 years".
    // Older records may contain only a number such as "2".
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return value == '1' ? '1 year' : '$value years';
    }

    return value;
  }

  DateTime? get _selectedDate {
    final rawDate = widget.schedule['date'];
    if (rawDate is DateTime) return rawDate;
    if (rawDate == null) return null;
    return DateTime.tryParse(rawDate.toString());
  }

  String get _formattedDate {
    final date = _selectedDate;
    if (date == null) return 'Not selected';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime? _scheduledDateTime() {
    final date = _selectedDate;
    final rawTime = widget.schedule['time']?.toString().trim();

    if (date == null || rawTime == null || rawTime.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(rawTime);

    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)?.toUpperCase();

    if (hour == null || minute < 0 || minute > 59) return null;

    if (period != null) {
      if (hour < 1 || hour > 12) return null;
      if (period == 'AM') {
        hour = hour == 12 ? 0 : hour;
      } else {
        hour = hour == 12 ? 12 : hour + 12;
      }
    } else if (hour < 0 || hour > 23) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  String get _formattedAddress {
    return [
      widget.pickupAddress['address'],
      widget.pickupAddress['area'],
      widget.pickupAddress['landmark'],
      widget.pickupAddress['city'],
      widget.pickupAddress['pincode'],
    ]
        .where((value) =>
            value != null && value.toString().trim().isNotEmpty)
        .join(', ');
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Booking se pehle mobile OTP se login karein.');
      return;
    }

    final petName = widget.dogDetails['name']?.toString().trim() ?? '';
    final address = widget.pickupAddress['address']?.toString().trim() ?? '';
    final dogId = widget.dogDetails['dogId']?.toString().trim() ?? '';
    final scheduledAt = _scheduledDateTime();

    if (petName.isEmpty) {
      _showMessage('Please dog ka naam check karein.');
      return;
    }

    if (dogId.isEmpty) {
      _showMessage(
        'Selected dog ki saved ID nahi mili. '
        'Dog selection screen par wapas jaakar dog select karein.',
      );
      return;
    }

    if (address.isEmpty || _formattedAddress.isEmpty) {
      _showMessage('Please pickup address check karein.');
      return;
    }

    if (scheduledAt == null) {
      _showMessage(
        'Date ya time sahi format mein nahi hai. '
        'Schedule screen par wapas jaakar check karein.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc();

      final bookingData = <String, dynamic>{
        'bookingId': bookingRef.id,
        'customerId': user.uid,
        'walkType': 'scheduled',
        'bookingPlan': _isRegular ? 'regular' : 'one_time',
        'serviceType': _isRegular ? 'regular_walk' : 'temporary_walk',
        'serviceName': _walkTypeLabel,
        'petName': petName,
        'dogId': dogId,

        // Includes breed, age, behaviour, special care and legacy notes.
        'petDetails': Map<String, dynamic>.from(widget.dogDetails),

        'pickupAddressId': 'booking_address',
        'pickupAddress':
            Map<String, dynamic>.from(widget.pickupAddress),

        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'duration': widget.schedule['duration']?.toString() ?? '',
        'preferredTime': widget.schedule['time']?.toString() ?? '',

        if (_isRegular) ...{
          'frequency': widget.schedule['frequency']?.toString() ?? '',
          'walksPerWeek': widget.schedule['walksPerWeek'],
        },

        'status': 'pending',
        'walkerId': null,
        'cancelRequest': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await bookingRef.set(bookingData);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: confirmationOrange,
            size: 58,
          ),
          title: const Text(
            'Booking Submitted!',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aapki booking request Firebase mein save ho gayi hai.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'Booking ID',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 5),
              SelectableText(
                bookingRef.id,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: confirmationOrange,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Walker assign hone tak booking pending rahegi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmationOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      final message = error.code == 'permission-denied'
          ? 'Firebase Rules ne booking save karne se roka. '
              'Firestore Rules aur booking fields check karne honge.'
          : 'Booking save nahi hui: ${error.message ?? error.code}';

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Kuch problem hui. Dobara try karein.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final behaviour = _stringList(widget.dogDetails['behaviour']);
    final specialCare = _stringList(widget.dogDetails['specialCare']);

    return Scaffold(
      backgroundColor: confirmationBackground,
      appBar: AppBar(
        backgroundColor: confirmationBackground,
        foregroundColor: confirmationText,
        elevation: 0,
        title: const Text(
          'Confirm Your Walk',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: confirmationOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: confirmationOrange,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Review Your Booking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: confirmationText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check all details before submitting your '
                    'walk request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionCard(
              title: 'Your Dog',
              icon: Icons.pets_rounded,
              children: [
                _detail('Name', _value(widget.dogDetails['name'])),
                _detail('Breed', _value(widget.dogDetails['breed'])),
                _detail('Age', _ageLabel(widget.dogDetails['age'])),
                _detail('Size', _value(widget.dogDetails['size'])),
                _detail('Gender', _value(widget.dogDetails['gender'])),

                if (behaviour.isNotEmpty)
                  _listDetail('Behaviour', behaviour),

                if (specialCare.isNotEmpty)
                  _listDetail('Special care', specialCare),

                if (_hasValue(widget.dogDetails['notes']))
                  _detail(
                    'Older notes',
                    _value(widget.dogDetails['notes']),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _sectionCard(
              title: 'Walk Details',
              icon: Icons.directions_walk_rounded,
              children: [
                _detail('Walk type', _walkTypeLabel),
                _detail('Date', _formattedDate),
                _detail(
                  'Preferred time',
                  _value(widget.schedule['time']),
                ),
                _detail(
                  'Duration',
                  _value(widget.schedule['duration']),
                ),
                if (_isRegular) ...[
                  _detail(
                    'Frequency',
                    _value(widget.schedule['frequency']),
                  ),
                  if (widget.schedule['frequency'] ==
                      'Selected days each week')
                    _detail(
                      'Walks per week',
                      '${_value(widget.schedule['walksPerWeek'])} days',
                    ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            _sectionCard(
              title: 'Pickup Location',
              icon: Icons.location_on_rounded,
              children: [
                _detail(
                  'Address type',
                  _value(widget.pickupAddress['label']),
                ),
                _detail(
                  'Full address',
                  _formattedAddress.isEmpty
                      ? 'Not provided'
                      : _formattedAddress,
                ),
              ],
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: confirmationOrange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Submit karne par booking request save hogi. '
                      'Walker assignment aur final confirmation alag '
                      'steps hain.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: confirmationText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmationOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.orange.shade200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined),
                          SizedBox(width: 9),
                          Text(
                            'Submit Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: confirmationText,
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Go Back and Edit',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: confirmationOrange, size: 23),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: confirmationText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  static Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: confirmationText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _listDetail(String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: values.map((value) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD5B0),
                    ),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: confirmationText,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
