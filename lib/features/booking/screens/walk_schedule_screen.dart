
import 'package:flutter/material.dart';

import '../services/walk_pricing_service.dart';
import 'booking_start_screen.dart';
import 'booking_confirmation_screen.dart';

const Color scheduleOrange = Color(0xFFFF7900);
const Color scheduleBackground = Color(0xFFFFFAF5);
const Color scheduleText = Color(0xFF202020);
const Color scheduleMuted = Color(0xFF777777);

class _WalkSlot {
  TimeOfDay time;
  int durationMinutes;

  _WalkSlot({
    required this.time,
    this.durationMinutes = 30,
  });
}

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

class _WalkScheduleScreenState
    extends State<WalkScheduleScreen> {
  int _walkCount = 2;

  final List<_WalkSlot> _slots = [
    _WalkSlot(time: const TimeOfDay(hour: 7, minute: 0)),
    _WalkSlot(time: const TimeOfDay(hour: 18, minute: 0)),
    _WalkSlot(time: const TimeOfDay(hour: 21, minute: 0)),
  ];

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _timeLabel(TimeOfDay time) {
    final hour = time.hour;

    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 16) return 'Afternoon';
    if (hour >= 16 && hour < 20) return 'Evening';
    return 'Night';
  }

  List<TimeOfDay> _suggestedTimes(int index) {
    if (index == 0) {
      return const [
        TimeOfDay(hour: 6, minute: 0),
        TimeOfDay(hour: 7, minute: 0),
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 9, minute: 0),
      ];
    }

    if (index == 1) {
      return const [
        TimeOfDay(hour: 16, minute: 0),
        TimeOfDay(hour: 17, minute: 0),
        TimeOfDay(hour: 18, minute: 0),
        TimeOfDay(hour: 19, minute: 0),
      ];
    }

    return const [
      TimeOfDay(hour: 20, minute: 0),
      TimeOfDay(hour: 21, minute: 0),
      TimeOfDay(hour: 22, minute: 0),
      TimeOfDay(hour: 23, minute: 0),
    ];
  }

  bool _sameTime(TimeOfDay a, TimeOfDay b) {
    return a.hour == b.hour && a.minute == b.minute;
  }

  Future<void> _chooseCustomTime(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _slots[index].time,
      helpText: 'Choose your walk start time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: scheduleOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: scheduleText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _slots[index].time = selected;
    });
  }

  Future<void> _chooseCustomDuration(int index) async {
    final controller = TextEditingController(
      text: _slots[index].durationMinutes.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Custom walk duration'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration in minutes',
              hintText: 'Example: 35',
              suffixText: 'min',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheduleOrange,
              ),
              onPressed: () {
                final value = int.tryParse(controller.text.trim());

                if (value == null || value < 1 || value > 240) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a duration between 1 and 240 minutes.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) return;

    setState(() {
      _slots[index].durationMinutes = result;
    });
  }

  int get _totalMinutes {
    return _slots
        .take(_walkCount)
        .fold(0, (total, slot) => total + slot.durationMinutes);
  }

  int? get _dailyPrice {
    return WalkPricingService.dailyEstimate(
      _slots
          .take(_walkCount)
          .map((slot) => slot.durationMinutes)
          .toList(),
    );
  }

  void _continueToReview() {
    final times = _slots
        .take(_walkCount)
        .map((slot) => _formatTime(slot.time))
        .toList();

    // Preserve the existing schedule keys and add the multi-walk data.
    final Map<String, dynamic> schedule = {
      'date': DateTime.now(),
      'time': times.first,
      'duration': _slots.first.durationMinutes,
      'isRegular': widget.walkType == WalkBookingType.regular,
      'frequency': 'Daily',
      'walksPerWeek': 7,
      'walkCount': _walkCount,
      'walks': _slots.take(_walkCount).map((slot) {
        return {
          'time': _formatTime(slot.time),
          'startHour': slot.time.hour,
          'startMinute': slot.time.minute,
          'duration': slot.durationMinutes,
          'period': _timeLabel(slot.time),
          'price': WalkPricingService.priceForDuration(
            slot.durationMinutes,
          ),
        };
      }).toList(),
      'dailyPrice': _dailyPrice,
      'totalDurationMinutes': _totalMinutes,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalkScheduleReviewScreen(
          walkType: widget.walkType,
          dogDetails: widget.dogDetails,
          pickupAddress: widget.pickupAddress,
          schedule: schedule,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: scheduleText,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  Widget _timeChip(int index, TimeOfDay time) {
    final selected = _sameTime(_slots[index].time, time);

    return ChoiceChip(
      label: Text(_formatTime(time)),
      selected: selected,
      selectedColor: const Color(0xFFFFE8D5),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? scheduleOrange : const Color(0xFFE8E1DA),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? const Color(0xFFC65C00) : scheduleText,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) {
        setState(() {
          _slots[index].time = time;
        });
      },
    );
  }

  Widget _walkCard(int index) {
    final slot = _slots[index];
    final suggestions = _suggestedTimes(index);
    final price = WalkPricingService.priceForDuration(
      slot.durationMinutes,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1E3D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Walk ${(index + 1).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheduleText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _timeLabel(slot.time),
                  style: const TextStyle(
                    color: Color(0xFFC65C00),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('1. Choose start time'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 5,
            runSpacing: 0,
            children: [
              ...suggestions.map((time) => _timeChip(index, time)),
              ActionChip(
                avatar: const Icon(
                  Icons.access_time,
                  size: 16,
                  color: scheduleOrange,
                ),
                label: const Text('Custom Time'),
                backgroundColor: const Color(0xFFFFF0E3),
                side: BorderSide(
                  color: suggestions.any(
                    (time) => _sameTime(time, slot.time),
                  )
                      ? const Color(0xFFE8E1DA)
                      : scheduleOrange,
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFFC65C00),
                  fontSize: 12,
                ),
                onPressed: () => _chooseCustomTime(index),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('2. Choose walk duration'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [20, 30, 45, 60].map((minutes) {
              final selected = slot.durationMinutes == minutes;

              return ChoiceChip(
                label: Text('$minutes min'),
                selected: selected,
                selectedColor: const Color(0xFFFFE8D5),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected
                      ? scheduleOrange
                      : const Color(0xFFE8E1DA),
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? const Color(0xFFC65C00)
                      : scheduleText,
                ),
                onSelected: (_) {
                  setState(() {
                    slot.durationMinutes = minutes;
                  });
                },
              );
            }).toList()
              ..add(
                ActionChip(
                  label: const Text('Custom'),
                  backgroundColor: slot.durationMinutes != 20 &&
                          slot.durationMinutes != 30 &&
                          slot.durationMinutes != 45 &&
                          slot.durationMinutes != 60
                      ? const Color(0xFFFFE8D5)
                      : Colors.white,
                  side: BorderSide(
                    color: slot.durationMinutes != 20 &&
                            slot.durationMinutes != 30 &&
                            slot.durationMinutes != 45 &&
                            slot.durationMinutes != 60
                        ? scheduleOrange
                        : const Color(0xFFE8E1DA),
                  ),
                  labelStyle: const TextStyle(
                    color: Color(0xFFC65C00),
                    fontSize: 12,
                  ),
                  onPressed: () => _chooseCustomDuration(index),
                ),
              ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1E3D6)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Price per walk',
                  style: TextStyle(
                    color: scheduleMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                price == null ? 'To be confirmed' : '₹$price',
                style: const TextStyle(
                  color: scheduleText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scheduleBackground,
      appBar: AppBar(
        backgroundColor: scheduleBackground,
        foregroundColor: scheduleText,
        elevation: 0,
        title: const Text(
          'Walk Schedule',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const Text(
              "Build your dog's daily routine",
              style: TextStyle(
                color: scheduleMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1E3D6)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.repeat, color: scheduleOrange, size: 25),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Walk Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheduleText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Repeats every day · Fixed routine',
                          style: TextStyle(
                            color: scheduleMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('How many walks per day?'),
            const SizedBox(height: 9),
            Row(
              children: [1, 2, 3].map((count) {
                final selected = _walkCount == count;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: count == 3 ? 0 : 8,
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _walkCount = count;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? const Color(0xFFFFE8D5)
                            : Colors.white,
                        foregroundColor: selected
                            ? const Color(0xFFC65C00)
                            : scheduleText,
                        side: BorderSide(
                          color: selected
                              ? scheduleOrange
                              : const Color(0xFFE8E1DA),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '$count ${count == 1 ? 'Walk' : 'Walks'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ...List.generate(_walkCount, _walkCard),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheduleOrange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Price Estimate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheduleText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryRow('Walks per day', '$_walkCount'),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Total walking time',
                    '$_totalMinutes minutes/day',
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    'Total per day',
                    _dailyPrice == null ? 'Price to be confirmed' : '₹$_dailyPrice',
                    emphasize: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₹149 is the draft price for a 30-minute walk. '
                    'Other durations need approved rates. '
                    'Booking depends on walker availability.',
                    style: TextStyle(
                      color: scheduleMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _continueToReview,
                style: FilledButton.styleFrom(
                  backgroundColor: scheduleOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue to Review',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Schedule selection does not confirm booking or payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheduleMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: scheduleMuted,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: emphasize ? scheduleOrange : scheduleText,
              fontWeight: FontWeight.w700,
              fontSize: emphasize ? 16 : 13,
            ),
          ),
        ),
      ],
    );
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
    final walks = (schedule['walks'] as List<dynamic>? ?? []);
    final dailyPrice = schedule['dailyPrice'];
    final totalMinutes = schedule['totalDurationMinutes'] ?? 0;

    return Scaffold(
      backgroundColor: scheduleBackground,
      appBar: AppBar(
        backgroundColor: scheduleBackground,
        foregroundColor: scheduleText,
        elevation: 0,
        title: const Text('Review Walk Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1E3D6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Daily Walk Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: scheduleText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Repeats every day · Fixed routine',
                  style: TextStyle(color: scheduleMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...walks.asMap().entries.map((entry) {
                  final walk = Map<String, dynamic>.from(entry.value as Map);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: scheduleOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Walk ${(entry.key + 1).toString().padLeft(2, '0')} · ${walk['period'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: scheduleText,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${walk['time']} · ${walk['duration']} minutes',
                                style: const TextStyle(
                                  color: scheduleMuted,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                walk['price'] == null
                                    ? 'Price to be confirmed'
                                    : '₹${walk['price']} per walk',
                                style: const TextStyle(
                                  color: scheduleText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                _reviewRow('Total walking time', '$totalMinutes minutes/day'),
                const SizedBox(height: 10),
                _reviewRow(
                  'Estimated daily total',
                  dailyPrice == null ? 'Price to be confirmed' : '₹$dailyPrice',
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1E3D6)),
            ),
            child: const Text(
              'Next: review your booking details. The final schedule '
              'depends on walker availability. Payment is handled separately.',
              style: TextStyle(
                color: scheduleMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheduleOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingConfirmationScreen(
                      walkType: walkType,
                      dogDetails: dogDetails,
                      pickupAddress: pickupAddress,
                      schedule: schedule,
                    ),
                  ),
                );
              },
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: scheduleMuted,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: emphasize ? scheduleOrange : scheduleText,
              fontWeight: FontWeight.w700,
              fontSize: emphasize ? 15 : 13,
            ),
          ),
        ),
      ],
    );
  }
}
