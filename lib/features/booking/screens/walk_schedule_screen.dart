
import 'package:flutter/material.dart';

import '../services/walk_pricing_service.dart';
import 'choose_walk_screen.dart';
import 'dog_pickup_details_screen.dart';

const Color scheduleOrange = Color(0xFFFF7900);
const Color scheduleBackground = Color(0xFFFFFAF5);
const Color scheduleText = Color(0xFF202020);
const Color scheduleMuted = Color(0xFF777777);

class _WalkSlot {
  TimeOfDay time;
  int durationMinutes;

  _WalkSlot({required this.time}) : durationMinutes = 30;
}

class WalkScheduleScreen extends StatefulWidget {
  const WalkScheduleScreen({
    super.key,
    required this.walkType,
  });

  final WalkBookingType walkType;

  @override
  State<WalkScheduleScreen> createState() => _WalkScheduleScreenState();
}

class _WalkScheduleScreenState extends State<WalkScheduleScreen> {
  int _walkCount = 1;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  final Set<DateTime> _selectedDates = <DateTime>{};

  final List<_WalkSlot> _slots = [
    _WalkSlot(time: const TimeOfDay(hour: 7, minute: 0)),
    _WalkSlot(time: const TimeOfDay(hour: 18, minute: 0)),
    _WalkSlot(time: const TimeOfDay(hour: 20, minute: 0)),
  ];

  bool get _isRegular => widget.walkType == WalkBookingType.regular;
  bool get _isChooseDates => widget.walkType == WalkBookingType.chooseDates;
  bool get _isOneTime => widget.walkType == WalkBookingType.oneTime;

  int get _effectiveWalkCount => _isOneTime ? 1 : _walkCount;

  List<DateTime> get _datesForBooking {
    if (_isChooseDates) {
      final dates = _selectedDates.toList()..sort();
      return dates;
    }
    return <DateTime>[_selectedDate];
  }

  String get _planTitle {
    if (_isRegular) return 'Daily Walk Plan';
    if (_isChooseDates) return 'Choose-Date Walk';
    return 'One-Time Walk';
  }

  String get _planSubtitle {
    if (_isRegular) return 'Repeats daily, including Sunday';
    if (_isChooseDates) return 'Choose one or more walk dates';
    return 'A one-time walk request';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
      TimeOfDay(hour: 18, minute: 0),
      TimeOfDay(hour: 19, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
      TimeOfDay(hour: 21, minute: 0),
    ];
  }

  bool _sameTime(TimeOfDay a, TimeOfDay b) =>
      a.hour == b.hour && a.minute == b.minute;

  DateTime _dateTimeForSlot(_WalkSlot slot, DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      slot.time.hour,
      slot.time.minute,
    );
  }

  int get _totalMinutes => _slots
      .take(_effectiveWalkCount)
      .fold<int>(0, (total, slot) => total + slot.durationMinutes);

  int? get _dailyPrice => WalkPricingService.dailyEstimate(
        _slots
            .take(_effectiveWalkCount)
            .map((slot) => slot.durationMinutes)
            .toList(),
      );

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<DateTime?> _showDatePicker({DateTime? initialDate}) async {
    final today = DateUtils.dateOnly(DateTime.now());

    return showDatePicker(
      context: context,
      initialDate: initialDate != null && !initialDate.isBefore(today)
          ? initialDate
          : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: _isRegular ? 'Choose plan start date' : 'Choose walk date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: scheduleOrange,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: scheduleText,
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _chooseDate() async {
    final selected = await _showDatePicker(initialDate: _selectedDate);
    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = DateUtils.dateOnly(selected);

      if (_isChooseDates) {
        _selectedDates.add(_selectedDate);
      }
    });
  }

  Future<void> _addAnotherDate() async {
    final selected = await _showDatePicker(initialDate: _selectedDate);
    if (selected == null || !mounted) return;

    final date = DateUtils.dateOnly(selected);

    if (_selectedDates.contains(date)) {
      _showMessage('This date is already selected.');
      return;
    }

    setState(() {
      _selectedDates.add(date);
      final dates = _selectedDates.toList()..sort();
      _selectedDate = dates.first;
    });
  }

  void _removeDate(DateTime date) {
    setState(() {
      _selectedDates.remove(date);
      final dates = _selectedDates.toList()..sort();

      if (dates.isNotEmpty) {
        _selectedDate = dates.first;
      }
    });
  }

  Future<void> _chooseCustomTime(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _slots[index].time,
      helpText: 'Choose walk start time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: scheduleOrange,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: scheduleText,
          ),
        ),
        child: child!,
      ),
    );

    if (selected == null || !mounted) return;

    setState(() => _slots[index].time = selected);
  }

  Future<void> _chooseCustomDuration(int index) async {
    final controller = TextEditingController(
      text: _slots[index].durationMinutes.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom walk duration'),
        content: TextField(
          controller: controller,
          autofocus: true,
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
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = int.tryParse(controller.text.trim());

              if (value == null || value < 1 || value > 240) {
                _showMessage(
                  'Enter a duration between 1 and 240 minutes.',
                );
                return;
              }

              Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || !mounted) return;

    setState(() => _slots[index].durationMinutes = result);
  }

  bool _hasOverlappingWalks() {
    final slots = _slots.take(_effectiveWalkCount).toList()
      ..sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });

    for (var i = 0; i < slots.length - 1; i++) {
      final currentStartMinutes =
          slots[i].time.hour * 60 + slots[i].time.minute;
      final currentEndMinutes =
          currentStartMinutes + slots[i].durationMinutes;
      final nextStartMinutes =
          slots[i + 1].time.hour * 60 + slots[i + 1].time.minute;

      if (currentEndMinutes > nextStartMinutes) return true;
    }

    return false;
  }

  String? _validateSchedule() {
    final today = DateUtils.dateOnly(DateTime.now());

    if (_isChooseDates && _selectedDates.isEmpty) {
      return 'Please select at least one walk date.';
    }

    final dates = _datesForBooking;

    if (dates.any((date) => DateUtils.dateOnly(date).isBefore(today))) {
      return 'Please select today or a future date.';
    }

    final now = DateTime.now();

    for (final date in dates) {
      for (final slot in _slots.take(_effectiveWalkCount)) {
        final start = _dateTimeForSlot(slot, date);

        if (!start.isAfter(now)) {
          return 'A selected walk time has passed. '
              'Choose a future time for today.';
        }
      }
    }

    for (final slot in _slots.take(_effectiveWalkCount)) {
      if (slot.durationMinutes < 1 || slot.durationMinutes > 240) {
        return 'Walk duration must be between 1 and 240 minutes.';
      }
    }

    if (_hasOverlappingWalks()) {
      return 'Walk timings overlap. Please change the time or duration.';
    }

    return null;
  }

  void _continueToDogDetails() {
    final validationMessage = _validateSchedule();

    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    final selectedSlots = _slots.take(_effectiveWalkCount).toList();
    final dates = _datesForBooking;

    final times = selectedSlots.map((slot) => _formatTime(slot.time)).toList();
    final formattedDates = dates.map(_formatDate).toList();

    final schedule = <String, dynamic>{
      // Existing single-date fields are retained for compatibility.
      'date': DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      'selectedDate': _formatDate(_selectedDate),

      // Additional fields for multi-date bookings.
      'selectedDates': dates
          .map((date) => DateTime(date.year, date.month, date.day))
          .toList(),
      'selectedDatesFormatted': formattedDates,

      'time': times.first,
      'duration': selectedSlots.first.durationMinutes,
      'isRegular': _isRegular,
      'isChooseDates': _isChooseDates,
      'frequency': _isRegular
          ? 'Daily'
          : _isChooseDates
              ? 'Custom'
              : 'One-Time',
      'walksPerWeek': _isRegular ? 7 : 0,
      'walkCount': _effectiveWalkCount,
      'walks': selectedSlots.map((slot) {
        return <String, dynamic>{
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

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DogPickupDetailsScreen(
          walkType: widget.walkType,
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
      ),
      onSelected: (_) => setState(() => _slots[index].time = time),
    );
  }

  Widget _walkCard(int index) {
    final slot = _slots[index];
    final suggestions = _suggestedTimes(index);
    final price = WalkPricingService.priceForDuration(slot.durationMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(
                _timeLabel(slot.time),
                style: const TextStyle(
                  color: Color(0xFFC65C00),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('Choose start time'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 5,
            runSpacing: 5,
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
                onPressed: () => _chooseCustomTime(index),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('Choose walk duration'),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ...[20, 30, 45, 60].map((minutes) {
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
                  onSelected: (_) {
                    setState(() => slot.durationMinutes = minutes);
                  },
                );
              }),
              ActionChip(
                label: const Text('Custom'),
                backgroundColor: const Color(0xFFFFF0E3),
                onPressed: () => _chooseCustomDuration(index),
              ),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Price per walk',
                  style: TextStyle(color: scheduleMuted, fontSize: 13),
                ),
              ),
              Text(
                price == null ? 'To be confirmed' : '₹$price',
                style: const TextStyle(
                  color: scheduleText,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateSelectionSection() {
    if (!_isChooseDates) return const SizedBox.shrink();

    final dates = _selectedDates.toList()..sort();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF1E3D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Selected walk dates',
                  style: TextStyle(
                    color: scheduleText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addAnotherDate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add date'),
                style: TextButton.styleFrom(
                  foregroundColor: scheduleOrange,
                ),
              ),
            ],
          ),
          if (dates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No dates selected yet. Add at least one date.',
                style: TextStyle(color: scheduleMuted, fontSize: 12),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dates.map((date) {
                return Chip(
                  label: Text(_formatDate(date)),
                  deleteIcon: const Icon(Icons.close, size: 17),
                  onDeleted: () => _removeDate(date),
                  backgroundColor: const Color(0xFFFFF0E3),
                  side: const BorderSide(color: Color(0xFFFFD2AE)),
                  labelStyle: const TextStyle(
                    color: scheduleText,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 6),
          const Text(
            'The selected walk times will be used on each chosen date.',
            style: TextStyle(
              color: scheduleMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: scheduleMuted, fontSize: 13),
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

  @override
  Widget build(BuildContext context) {
    final count = _effectiveWalkCount;
    final selectedDateCount = _isChooseDates ? _selectedDates.length : 1;

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
            Text(
              _isRegular
                  ? "Build your dog's daily routine"
                  : _isChooseDates
                      ? 'Choose your walk dates and times'
                      : 'Plan your one-time walk',
              style: const TextStyle(color: scheduleMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1E3D6)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isRegular ? Icons.repeat : Icons.pets,
                    color: scheduleOrange,
                    size: 25,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _planTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheduleText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _planSubtitle,
                          style: const TextStyle(
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
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _chooseDate,
              icon: const Icon(
                Icons.calendar_month,
                color: scheduleOrange,
              ),
              label: Text(
                '${_isRegular ? 'Plan start date' : 'Walk date'}: '
                '${_formatDate(_selectedDate)}',
                style: const TextStyle(color: scheduleText),
              ),
            ),
            _dateSelectionSection(),
            const SizedBox(height: 20),
            if (_isOneTime) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: scheduleOrange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'One-Time booking mein sirf ek walk select kar sakte hain.',
                        style: TextStyle(color: scheduleText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              _sectionTitle('How many walks per day?'),
              const SizedBox(height: 9),
              Row(
                children: [1, 2, 3].map((countOption) {
                  final selected = _walkCount == countOption;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: countOption == 3 ? 0 : 8,
                      ),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _walkCount = countOption);
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
                          '$countOption ${countOption == 1 ? 'Walk' : 'Walks'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            ...List.generate(count, _walkCard),
            const SizedBox(height: 4),
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
                    'Price Estimate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheduleText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _summaryRow(
                    _isChooseDates ? 'Selected dates' : 'Walks per day',
                    _isChooseDates ? '$selectedDateCount' : '$count',
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Total walking time',
                    '$_totalMinutes minutes/day',
                  ),
                  const Divider(height: 24),
                  _summaryRow(
                    _isRegular
                        ? 'Estimated daily total'
                        : _isChooseDates
                            ? 'Estimated total per selected date'
                            : 'Estimated total',
                    _dailyPrice == null
                        ? 'Price to be confirmed'
                        : '₹$_dailyPrice',
                    emphasize: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Current draft rate: ₹149 per 30-minute walk. '
                    'Other durations require approved rates. '
                    'This is a price estimate, not a payment.',
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
                onPressed: _continueToDogDetails,
                style: FilledButton.styleFrom(
                  backgroundColor: scheduleOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue to Dog & Pickup Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your booking request is not confirmed at this step.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheduleMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
