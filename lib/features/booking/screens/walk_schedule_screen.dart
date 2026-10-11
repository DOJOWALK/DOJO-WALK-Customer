import 'package:flutter/material.dart';

import 'booking_start_screen.dart';
import 'booking_confirmation_screen.dart';

const Color scheduleOrange = Color(0xFFFF7900);
const Color scheduleBackground = Color(0xFFFFFAF5);
const Color scheduleText = Color(0xFF202020);

class WalkScheduleScreen extends StatefulWidget {
  const WalkScheduleScreen({
    super.key,
    required this.walkType,
    required this.dogDetails,
    required this.pickupAddress,
  });

  final WalkBookingType walkType;
  final Map<String, dynamic> dogDetails;
  final Map<String, dynamic> pickupAddress;

  @override
  State<WalkScheduleScreen> createState() =>
      _WalkScheduleScreenState();
}

class _WalkScheduleScreenState extends State<WalkScheduleScreen> {
  DateTime _selectedDate =
      DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));

  String? _selectedTime;
  String _duration = '30 minutes';
  String _frequency = 'Daily';
  int _walksPerWeek = 5;

  final List<String> _timeSlots = const [
    '6:00 AM',
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
  ];

  bool get _isRegular =>
      widget.walkType == WalkBookingType.regular;

  Future<void> _chooseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today)
          ? today
          : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Select walk date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: scheduleOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(result);
      });
    }
  }

  void _continue() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preferred walk time.'),
        ),
      );
      return;
    }

    final schedule = <String, dynamic>{
      'date': DateUtils.dateOnly(_selectedDate).toIso8601String(),
      'time': _selectedTime,
      'duration': _duration,
      'isRegular': _isRegular,
      'frequency': _isRegular ? _frequency : null,
      'walksPerWeek': _isRegular &&
              _frequency == 'Selected days each week'
          ? _walksPerWeek
          : null,
    };

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalkScheduleReviewScreen(
          walkType: widget.walkType,
          dogDetails: widget.dogDetails,
          pickupAddress: widget.pickupAddress,
          schedule: schedule,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scheduleBackground,
      appBar: AppBar(
        backgroundColor: scheduleBackground,
        title: const Text(
          'Walk Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: scheduleText,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              'Plan your dog’s walk',
              style: TextStyle(
                fontSize: 27,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: scheduleText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your preferred date, time and walk duration.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('1. Select date'),
            const SizedBox(height: 10),

            InkWell(
              onTap: _chooseDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: scheduleOrange,
                      size: 30,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preferred date',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('2. Preferred time'),
            const SizedBox(height: 6),
            const Text(
              'Choose a time that works for you.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((time) {
                final selected = _selectedTime == time;

                return ChoiceChip(
                  label: Text(time),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor:
                      scheduleOrange.withValues(alpha: 0.15),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? scheduleOrange
                        : const Color(0xFFE7E7E7),
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? scheduleOrange
                        : const Color(0xFF303030),
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedTime = time);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            _sectionTitle('3. Walk duration'),
            const SizedBox(height: 12),

            ...[
              '20 minutes',
              '30 minutes',
              '45 minutes',
              '60 minutes',
            ].map((duration) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _optionTile(
                  title: duration,
                  subtitle: duration == '30 minutes'
                      ? 'A popular choice'
                      : 'Preferred walk length',
                  selected: _duration == duration,
                  icon: Icons.timer_outlined,
                  onTap: () {
                    setState(() => _duration = duration);
                  },
                ),
              );
            }),

            if (_isRegular) ...[
              const SizedBox(height: 14),
              _sectionTitle('4. Repeat schedule'),
              const SizedBox(height: 12),

              ...[
                'Daily',
                'Selected days each week',
              ].map((frequency) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _optionTile(
                    title: frequency,
                    subtitle: frequency == 'Daily'
                        ? 'Request a walk every day'
                        : 'Choose how many days per week',
                    selected: _frequency == frequency,
                    icon: Icons.repeat_rounded,
                    onTap: () {
                      setState(() => _frequency = frequency);
                    },
                  ),
                );
              }),

              if (_frequency == 'Selected days each week') ...[
                const SizedBox(height: 6),
                const Text(
                  'Walks per week',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [2, 3, 4, 5, 6].map((days) {
                    return ChoiceChip(
                      label: Text('$days days'),
                      selected: _walksPerWeek == days,
                      selectedColor:
                          scheduleOrange.withValues(alpha: 0.15),
                      onSelected: (_) {
                        setState(() => _walksPerWeek = days);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFEEEEEE),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: scheduleOrange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These are preferred times, not confirmed '
                      'availability. Actual walker availability '
                      'must be checked before booking.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.black54,
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
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheduleOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Review Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: scheduleText,
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? scheduleOrange
                : const Color(0xFFE7E7E7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheduleOrange, size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? scheduleOrange : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E7E7)),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class WalkScheduleReviewScreen extends StatelessWidget {
  const WalkScheduleReviewScreen({
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
  Widget build(BuildContext context) {
    final date = DateTime.parse(schedule['date'] as String);

    final address = [
      pickupAddress['address'],
      pickupAddress['area'],
      pickupAddress['landmark'],
      pickupAddress['city'],
      pickupAddress['pincode'],
    ]
        .where((value) =>
            value != null && value.toString().trim().isNotEmpty)
        .join(', ');

    Widget detail(String label, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheduleOrange, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheduleBackground,
      appBar: AppBar(
        backgroundColor: scheduleBackground,
        title: const Text(
          'Review Booking',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your walk details',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: scheduleText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your selections before moving to confirmation.',
              style: TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  detail(
                    'Dog',
                    (dogDetails['name'] ?? 'Not provided').toString(),
                    Icons.pets_rounded,
                  ),
                  detail(
                    'Walk type',
                    walkType == WalkBookingType.regular
                        ? 'Regular Walks'
                        : 'One-Time Walk',
                    Icons.directions_walk_rounded,
                  ),
                  detail(
                    'Pickup address',
                    address.isEmpty ? 'Not provided' : address,
                    Icons.location_on_rounded,
                  ),
                  detail(
                    'Date',
                    '${date.day}/${date.month}/${date.year}',
                    Icons.calendar_month_rounded,
                  ),
                  detail(
                    'Preferred time',
                    (schedule['time'] ?? 'Not selected').toString(),
                    Icons.access_time_rounded,
                  ),
                  detail(
                    'Duration',
                    (schedule['duration'] ?? 'Not selected').toString(),
                    Icons.timer_outlined,
                  ),
                  if (schedule['isRegular'] == true) ...[
                    detail(
                      'Frequency',
                      (schedule['frequency'] ?? 'Not selected').toString(),
                      Icons.repeat_rounded,
                    ),
                    if (schedule['frequency'] ==
                        'Selected days each week')
                      detail(
                        'Walks per week',
                        '${schedule['walksPerWeek'] ?? '-'} days',
                        Icons.date_range_rounded,
                      ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Text(
                'This is a review only. Your booking is not yet '
                'confirmed, and no payment has been taken.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookingConfirmationScreen(
                        walkType: walkType,
                        dogDetails: dogDetails,
                        pickupAddress: pickupAddress,
                        schedule: schedule,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheduleOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Continue to Confirmation',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheduleText,
                  side: const BorderSide(
                    color: Color(0xFFDDDDDD),
                  ),
                ),
                child: const Text('Edit Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
