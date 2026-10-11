import 'package:flutter/material.dart';

import 'booking_start_screen.dart';

const Color confirmationOrange = Color(0xFFFF7900);
const Color confirmationBackground = Color(0xFFFFFAF5);
const Color confirmationText = Color(0xFF202020);

class BookingConfirmationScreen extends StatelessWidget {
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

  bool get _isRegular => walkType == WalkBookingType.regular;

  String get _walkTypeLabel =>
      _isRegular ? 'Regular Walks' : 'One-Time Walk';

  String get _formattedDate {
    final rawDate = schedule['date'];

    if (rawDate == null) return 'Not selected';

    final date = DateTime.tryParse(rawDate.toString());

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

  String get _formattedAddress {
    return [
      pickupAddress['address'],
      pickupAddress['area'],
      pickupAddress['landmark'],
      pickupAddress['city'],
      pickupAddress['pincode'],
    ]
        .where(
          (value) =>
              value != null && value.toString().trim().isNotEmpty,
        )
        .join(', ');
  }

  void _submitBooking(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Booking submission setup pending. Firebase booking save '
          'will be connected in the next step.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                border: Border.all(
                  color: const Color(0xFFEEEEEE),
                ),
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
                _detail('Name', _value(dogDetails['name'])),
                _detail('Breed', _value(dogDetails['breed'])),
                _detail('Age', _ageLabel(dogDetails['age'])),
                _detail('Size', _value(dogDetails['size'])),
                _detail('Gender', _value(dogDetails['gender'])),
                if (_hasValue(dogDetails['notes']))
                  _detail('Special notes', _value(dogDetails['notes'])),
              ],
            ),

            const SizedBox(height: 16),

            _sectionCard(
              title: 'Walk Details',
              icon: Icons.directions_walk_rounded,
              children: [
                _detail('Walk type', _walkTypeLabel),
                _detail('Date', _formattedDate),
                _detail('Preferred time', _value(schedule['time'])),
                _detail('Duration', _value(schedule['duration'])),
                if (_isRegular) ...[
                  _detail('Frequency', _value(schedule['frequency'])),
                  if (schedule['frequency'] == 'Selected days each week')
                    _detail(
                      'Walks per week',
                      '${_value(schedule['walksPerWeek'])} days',
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
                  _value(pickupAddress['label']),
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
                      'Your details are ready for review. Your booking '
                      'is not submitted or confirmed yet. The booking '
                      'submission system will be connected next.',
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
                onPressed: () => _submitBooking(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmationOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Row(
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
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: confirmationText,
                  side: const BorderSide(
                    color: Color(0xFFDDDDDD),
                  ),
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

  static bool _hasValue(dynamic value) {
    return value != null && value.toString().trim().isNotEmpty;
  }

  static String _value(dynamic value) {
    if (!_hasValue(value)) return 'Not provided';
    return value.toString();
  }

  static String _ageLabel(dynamic age) {
    if (!_hasValue(age)) return 'Not provided';
    return '$age years';
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
}
