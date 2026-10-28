import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/screens/phone_login_screen.dart';
import '../../profile/screens/name_setup_screen.dart';
import '../services/walk_pricing_service.dart';
import 'dog_selection_screen.dart';

const Color bookingOrange = Color(0xFFFF7900);
const Color bookingBackground = Color(0xFFFFFAF5);
const Color bookingText = Color(0xFF252525);
const Color bookingMuted = Color(0xFF777777);

enum WalkBookingType {
  oneTime,
  regular,
  chooseDates,
}

class _WalkSlot {
  TimeOfDay time;
  int durationMinutes;

  _WalkSlot({
    required this.time,
    required this.durationMinutes,
  });

  Map<String, dynamic> toMap() {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');

    return {
      'time': '$displayHour:$formattedMinute $period',
      'startHour': hour,
      'startMinute': minute,
      'duration': durationMinutes,
      'period': hour < 12
          ? 'Morning'
          : hour < 16
              ? 'Afternoon'
              : hour < 21
                  ? 'Evening'
                  : 'Night',
      'price': WalkPricingService.priceForDuration(durationMinutes),
    };
  }
}

class ChooseWalkScreen extends StatefulWidget {
  const ChooseWalkScreen({super.key});

  @override
  State<ChooseWalkScreen> createState() => _ChooseWalkScreenState();
}

class _ChooseWalkScreenState extends State<ChooseWalkScreen> {
  WalkBookingType? _selectedType;

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  final Set<DateTime> _selectedDates = {};

  final Map<DateTime, List<_WalkSlot>> _dateSchedules = {};

  int _walkCount = 1;

  bool _isContinuing = false;

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<_WalkSlot> get _currentSlots {
    final date = _dateOnly(_selectedDate);

    if (_selectedType == WalkBookingType.oneTime) {
      return [
        _dateSchedules.putIfAbsent(
          date,
          () => [
            _WalkSlot(
              time: TimeOfDay.fromDateTime(
                DateTime.now().add(const Duration(hours: 1)),
              ),
              durationMinutes: 30,
            ),
          ],
        ).first,
      ];
    }

    return _dateSchedules.putIfAbsent(
      date,
      () => _makeDefaultSlots(_walkCount),
    );
  }

  List<_WalkSlot> _makeDefaultSlots(int count) {
    const defaults = [
      TimeOfDay(hour: 7, minute: 0),
      TimeOfDay(hour: 18, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ];

    return List.generate(
      count.clamp(1, 3),
      (index) => _WalkSlot(
        time: defaults[index],
        durationMinutes: 30,
      ),
    );
  }

  bool get _isRegular => _selectedType == WalkBookingType.regular;

  bool get _isChooseDates =>
      _selectedType == WalkBookingType.chooseDates;

  bool get _isOneTime => _selectedType == WalkBookingType.oneTime;

  String _formatDate(DateTime date) {
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  int? _slotPrice(_WalkSlot slot) {
    return WalkPricingService.priceForDuration(
      slot.durationMinutes,
    );
  }

  int? _priceForSlots(List<_WalkSlot> slots) {
    var total = 0;

    for (final slot in slots) {
      final price = _slotPrice(slot);

      if (price == null) return null;

      total += price;
    }

    return total;
  }

  int get _totalDurationMinutes {
    return _currentSlots.fold<int>(
      0,
      (total, slot) => total + slot.durationMinutes,
    );
  }

  Future<void> _selectType(WalkBookingType type) async {
    setState(() {
      _selectedType = type;
      _walkCount = 1;
      _selectedDate = _dateOnly(DateTime.now());

      _selectedDates.clear();
      _dateSchedules.clear();

      if (type == WalkBookingType.chooseDates) {
        _selectedDates.add(_selectedDate);
      }

      _dateSchedules[_selectedDate] = _makeDefaultSlots(1);
    });
  }

  void _changeWalkCount(int count) {
    if (count < 1 || count > 3) return;

    setState(() {
      _walkCount = count;

      if (_selectedType == WalkBookingType.oneTime) {
        return;
      }

      final date = _dateOnly(_selectedDate);
      final existing = _dateSchedules[date] ?? [];
      final defaults = _makeDefaultSlots(count);
      final updated = <_WalkSlot>[];

      for (var i = 0; i < count; i++) {
        if (i < existing.length) {
          updated.add(existing[i]);
        } else {
          updated.add(defaults[i]);
        }
      }

      _dateSchedules[date] = updated;
    });
  }

  Future<void> _chooseDate() async {
    final now = _dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select walk date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: bookingOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: bookingText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    final date = _dateOnly(picked);

    setState(() {
      _selectedDate = date;

      _dateSchedules.putIfAbsent(
        date,
        () => _makeDefaultSlots(_walkCount),
      );

      if (_isChooseDates) {
        _selectedDates.add(date);
      }

      _walkCount = _dateSchedules[date]?.length ?? 1;
    });
  }

  void _selectScheduleDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);

      _dateSchedules.putIfAbsent(
        _selectedDate,
        () => _makeDefaultSlots(_walkCount),
      );

      _walkCount = _dateSchedules[_selectedDate]?.length ?? 1;
    });
  }

  void _removeDate(DateTime date) {
    if (_selectedDates.length <= 1) {
      _message('Kam se kam ek date select rakhein.');
      return;
    }

    setState(() {
      final normalized = _dateOnly(date);

      _selectedDates.remove(normalized);
      _dateSchedules.remove(normalized);

      if (_selectedDate == normalized) {
        final remaining = _selectedDates.toList()
          ..sort((a, b) => a.compareTo(b));

        _selectedDate = remaining.first;
        _walkCount = _dateSchedules[_selectedDate]?.length ?? 1;
      }
    });
  }

  Future<void> _chooseTime(_WalkSlot slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: slot.time,
      helpText: 'Select walk time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: bookingOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: bookingText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      slot.time = picked;
    });
  }

  Future<void> _chooseDuration(_WalkSlot slot) async {
    final controller = TextEditingController(
      text: slot.durationMinutes.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Custom Duration'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              hintText: 'Enter 1–240 minutes',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: bookingOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final minutes = int.tryParse(controller.text.trim());

                if (minutes == null || minutes < 1 || minutes > 240) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('1 se 240 minutes enter karein.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, minutes);
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
      slot.durationMinutes = result;
    });
  }

  DateTime _dateTimeForSlot(DateTime date, _WalkSlot slot) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      slot.time.hour,
      slot.time.minute,
    );
  }

  String? _validateSlots(DateTime date, List<_WalkSlot> slots) {
    if (slots.isEmpty || slots.length > 3) {
      return 'Har din mein 1 se 3 walks select karein.';
    }

    final now = DateTime.now();
    final normalizedDate = _dateOnly(date);
    final today = _dateOnly(now);

    for (final slot in slots) {
      if (slot.durationMinutes < 1 || slot.durationMinutes > 240) {
        return 'Walk duration 1 se 240 minutes ke beech honi chahiye.';
      }

      final start = _dateTimeForSlot(normalizedDate, slot);

      // Walk Now is an immediate request, not a scheduled time.
      if (_isOneTime) continue;

      // Regular plans may start today if there is a future walk time.
      if (_isRegular && normalizedDate == today) {
        if (!start.isAfter(now)) {
          continue;
        }
      } else if (!start.isAfter(now)) {
        return '${_formatTime(slot.time)} ka time beet chuka hai. '
            'Future time select karein.';
      }
    }

    final sorted = [...slots]
      ..sort((a, b) {
        final first = a.time.hour * 60 + a.time.minute;
        final second = b.time.hour * 60 + b.time.minute;

        return first.compareTo(second);
      });

    for (var i = 0; i < sorted.length - 1; i++) {
      final firstStart = _dateTimeForSlot(normalizedDate, sorted[i]);
      final secondStart = _dateTimeForSlot(normalizedDate, sorted[i + 1]);

      final firstEnd = firstStart.add(
        Duration(minutes: sorted[i].durationMinutes),
      );

      if (secondStart.isBefore(firstEnd)) {
        return 'Do walks ka time overlap ho raha hai. Time change karein.';
      }
    }

    return null;
  }

  DateTime? _regularStartDate() {
    if (!_isRegular) return _selectedDate;

    final today = _dateOnly(DateTime.now());
    final slots = _dateSchedules[_dateOnly(_selectedDate)] ?? _currentSlots;
    final now = DateTime.now();

    final hasFutureSlotToday = slots.any((slot) {
      return _dateTimeForSlot(today, slot).isAfter(now);
    });

    if (hasFutureSlotToday) {
      return today;
    }

    return today.add(const Duration(days: 1));
  }

  List<Map<String, dynamic>> _serializeSlots(List<_WalkSlot> slots) {
    return slots.map((slot) => slot.toMap()).toList();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  DateTime? _parseDob(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  int _ageOnDate(DateTime dob, DateTime today) {
    return today.year -
        dob.year -
        ((today.month < dob.month ||
                (today.month == dob.month && today.day < dob.day))
            ? 1
            : 0);
  }

  Future<bool> _ensureCustomerProfile(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data() ?? <String, dynamic>{};
    final name = (data['name'] ?? '').toString().trim();
    final dob = _parseDob(data['dateOfBirth']);
    final today = DateUtils.dateOnly(DateTime.now());

    if (name.isNotEmpty &&
        dob != null &&
        _ageOnDate(dob, today) >= 18) {
      return true;
    }

    if (!mounted) return false;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NameSetupScreen(
          bookingWalkType: _selectedType!.name,
        ),
      ),
    );

    if (!mounted) return false;

    final refreshed = FirebaseAuth.instance.currentUser;

    if (refreshed == null) {
      _message('Please login karke profile complete karein.');
      return false;
    }

    final refreshedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(refreshed.uid)
        .get();

    final refreshedData = refreshedDoc.data() ?? <String, dynamic>{};

    final refreshedName =
        (refreshedData['name'] ?? '').toString().trim();

    final refreshedDob = _parseDob(refreshedData['dateOfBirth']);

    if (refreshedName.isEmpty || refreshedDob == null) {
      _message('Pehle apna profile complete karein.');
      return false;
    }

    if (_ageOnDate(refreshedDob, today) < 18) {
      _message('Booking ke liye customer ki age 18+ honi chahiye.');
      return false;
    }

    return true;
  }

  Future<void> _continueToDogSelection() async {
    if (_selectedType == null) {
      _message('Please Walk Type select karein.');
      return;
    }

    if (_isChooseDates && _selectedDates.isEmpty) {
      _message('Please kam se kam ek date select karein.');
      return;
    }

    if (_isOneTime) {
      // Walk Now is an immediate request.
      // Actual availability is not confirmed here.
    } else if (_isRegular) {
      final today = _dateOnly(DateTime.now());
      final startDate = _regularStartDate() ?? today;
      final startSlots = _dateSchedules[_dateOnly(_selectedDate)] ??
          _currentSlots;

      final applicableSlots = startDate == today
          ? startSlots
              .where(
                (slot) => _dateTimeForSlot(today, slot).isAfter(
                  DateTime.now(),
                ),
              )
              .toList()
          : startSlots;

      if (applicableSlots.isEmpty) {
        _message(
          'Aaj ke liye future time nahi hai. Kal se plan start hoga.',
        );
        return;
      }

      final error = _validateSlots(startDate, applicableSlots);

      if (error != null) {
        _message(error);
        return;
      }
    } else {
      for (final date in _selectedDates) {
        final slots = _dateSchedules[_dateOnly(date)] ?? [];

        final error = _validateSlots(date, slots);

        if (error != null) {
          _message('${_formatDate(date)}: $error');
          return;
        }
      }
    }

    setState(() => _isContinuing = true);

    try {
      var user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhoneLoginScreen(
              bookingWalkType: _selectedType!.name,
            ),
          ),
        );

        if (!mounted) return;

        user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          _message('Booking continue karne ke liye login karein.');
          return;
        }
      }

      final profileComplete = await _ensureCustomerProfile(user);

      if (!mounted || !profileComplete) return;

      final schedule = _buildSchedule();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DogSelectionScreen(
            walkType: _selectedType!,
            schedule: schedule,
          ),
        ),
      );
    } catch (e) {
      _message('Aage continue nahi ho paya: $e');
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  Map<String, dynamic> _buildSchedule() {
    final now = DateTime.now();
    final today = _dateOnly(now);

    if (_isOneTime) {
      final slot = _currentSlots.first;

      return {
        'date': today,
        'selectedDate': _formatDate(today),
        'isImmediate': true,
        'isRegular': false,
        'isChooseDates': false,
        'frequency': 'One-Time',
        'walkCount': 1,
        'walks': [
          {
            'time': 'ASAP',
            'duration': slot.durationMinutes,
            'price': _slotPrice(slot),
          },
        ],
        'dailyPrice': _slotPrice(slot),
      };
    }

    if (_isRegular) {
      final startDate = _regularStartDate() ?? today;
      final originalSlots =
          _dateSchedules[_dateOnly(_selectedDate)] ?? _currentSlots;

      final startSlots = startDate == today
          ? originalSlots
              .where(
                (slot) => _dateTimeForSlot(today, slot).isAfter(now),
              )
              .toList()
          : originalSlots;

      final slots = startSlots.isEmpty ? originalSlots : startSlots;
      final firstSlot = slots.first;

      return {
        'date': startDate,
        'selectedDate': _formatDate(startDate),
        'isImmediate': false,
        'isRegular': true,
        'isChooseDates': false,
        'frequency': 'Daily',
        'walksPerWeek': 7,
        'walkCount': slots.length,
        'time': _formatTime(firstSlot.time),
        'duration': firstSlot.durationMinutes,
        'walks': _serializeSlots(slots),
        'dailyPrice': _priceForSlots(slots),
      };
    }

    final sortedDates = _selectedDates.toList()
      ..sort((a, b) => a.compareTo(b));

    final dateSchedules = <Map<String, dynamic>>[];

    for (final date in sortedDates) {
      final slots = _dateSchedules[_dateOnly(date)] ?? [];

      dateSchedules.add({
        'date': date,
        'dateFormatted': _formatDate(date),
        'walkCount': slots.length,
        'walks': _serializeSlots(slots),
        'dailyPrice': _priceForSlots(slots),
      });
    }

    final firstDate = sortedDates.first;
    final firstDaySlots =
        _dateSchedules[_dateOnly(firstDate)] ?? _currentSlots;

    return {
      'date': firstDate,
      'selectedDate': _formatDate(firstDate),
      'selectedDates': sortedDates,
      'selectedDatesFormatted': sortedDates.map(_formatDate).toList(),
      'isImmediate': false,
      'isRegular': false,
      'isChooseDates': true,
      'frequency': 'Custom',
      'walkCount': firstDaySlots.length,
      'walks': _serializeSlots(firstDaySlots),
      'dateSchedules': dateSchedules,
      'dailyPrice': _priceForSlots(firstDaySlots),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bookingBackground,
      appBar: AppBar(
        backgroundColor: bookingOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Book a Walk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Choose your walk type',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: bookingText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apne dog ke liye suitable walk plan select karein.',
              style: TextStyle(color: bookingMuted),
            ),
            const SizedBox(height: 16),
            _typeCard(
              type: WalkBookingType.oneTime,
              title: 'Walk Now',
              subtitle: 'Ek one-time walk request karein.',
              icon: Icons.flash_on_outlined,
            ),
            const SizedBox(height: 10),
            _typeCard(
              type: WalkBookingType.regular,
              title: 'Daily Walk',
              subtitle: 'Har din repeat hone wala regular plan.',
              icon: Icons.repeat,
            ),
            const SizedBox(height: 10),
            _typeCard(
              type: WalkBookingType.chooseDates,
              title: 'Choose Dates',
              subtitle: 'Apni pasand ki dates aur walks select karein.',
              icon: Icons.calendar_month,
            ),
            if (_selectedType != null) ...[
              const SizedBox(height: 22),
              _sectionCard(
                title: 'Schedule Setup',
                icon: Icons.schedule,
                child: _buildScheduleSetup(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed:
                    _isContinuing ? null : _continueToDogSelection,
                style: FilledButton.styleFrom(
                  backgroundColor: bookingOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isContinuing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue to Dog Selection',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCard({
    required WalkBookingType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _selectedType == type;

    return InkWell(
      onTap: () => _selectType(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE9D6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? bookingOrange : const Color(0xFFF0E2D5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? bookingOrange : bookingBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : bookingOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: bookingText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: bookingMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? bookingOrange : bookingMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSetup() {
    if (_isOneTime) {
      final slot = _currentSlots.first;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Walk Now request',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: bookingText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aapki request ASAP ke liye hogi. Actual walker availability '
            'request submit hone ke baad confirm hogi.',
            style: TextStyle(
              color: bookingMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _durationSelector(slot),
          const SizedBox(height: 10),
          _priceLine(_slotPrice(slot)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isChooseDates) ...[
          const Text(
            'Select dates',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _chooseDate,
            icon: const Icon(Icons.add),
            label: const Text('Add / Select Date'),
            style: OutlinedButton.styleFrom(
              foregroundColor: bookingOrange,
              side: const BorderSide(color: bookingOrange),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildDateChips(),
          ),
          const SizedBox(height: 8),
          if (_selectedDates.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _removeDate(_selectedDate),
                child: const Text(
                  'Remove selected date',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Editing: ${_formatDate(_selectedDate)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: bookingOrange,
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          const Text(
            'Daily plan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Plan har din repeat hoga, Monday se Sunday tak. '
            'Off days baad mein support ke through manage honge.',
            style: TextStyle(color: bookingMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
        ],
        if (_isRegular) ...[
          const Text(
            'Walks per day',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [1, 2, 3].map((count) {
              return ChoiceChip(
                label: Text('$count ${count == 1 ? 'Walk' : 'Walks'}'),
                selected: _walkCount == count,
                selectedColor: const Color(0xFFFFE0C2),
                onSelected: (_) => _changeWalkCount(count),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        ..._currentSlots.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _walkSlotCard(entry.key + 1, entry.value),
          );
        }),
        const Divider(height: 24),
        _detailLine(
          'Total daily duration',
          '$_totalDurationMinutes minutes',
        ),
        const SizedBox(height: 8),
        _detailLine(
          _isRegular ? 'Estimated daily total' : 'Estimated date total',
          _priceForSlots(_currentSlots) == null
              ? 'Price to be confirmed'
              : '₹${_priceForSlots(_currentSlots)}',
        ),
        if (_isRegular) ...[
          const SizedBox(height: 12),
          _detailLine(
            'Starting date',
            _formatDate(_regularStartDate() ?? _selectedDate),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Price is an estimate. Final pricing and walker availability '
          'must be confirmed before the booking is accepted.',
          style: TextStyle(
            fontSize: 12,
            color: bookingMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDateChips() {
    final sortedDates = _selectedDates.toList()
      ..sort((a, b) => a.compareTo(b));

    return sortedDates.map((date) {
      final selected = _dateOnly(date) == _selectedDate;

      return ChoiceChip(
        label: Text(_formatDate(date)),
        selected: selected,
        selectedColor: const Color(0xFFFFE0C2),
        onSelected: (_) => _selectScheduleDate(date),
      );
    }).toList();
  }

  Widget _durationSelector(_WalkSlot slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: bookingText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [20, 30, 45, 60].map((minutes) {
            return ChoiceChip(
              label: Text('$minutes min'),
              selected: slot.durationMinutes == minutes,
              selectedColor: const Color(0xFFFFE0C2),
              onSelected: (_) {
                setState(() {
                  slot.durationMinutes = minutes;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _chooseDuration(slot),
            child: const Text(
              'Custom duration',
              style: TextStyle(color: bookingOrange),
            ),
          ),
        ),
      ],
    );
  }

  Widget _walkSlotCard(int number, _WalkSlot slot) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bookingBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0E2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walk $number',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: bookingText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, color: bookingOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatTime(slot.time),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => _chooseTime(slot),
                child: const Text(
                  'Change',
                  style: TextStyle(color: bookingOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _durationSelector(slot),
          _priceLine(_slotPrice(slot)),
        ],
      ),
    );
  }

  Widget _priceLine(int? price) {
    return Row(
      children: [
        const Text(
          'Estimated price',
          style: TextStyle(color: bookingMuted),
        ),
        const Spacer(),
        Text(
          price == null ? 'To be confirmed' : '₹$price',
          style: const TextStyle(
            color: bookingOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _detailLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: bookingMuted),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: bookingText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
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
              Icon(icon, color: bookingOrange),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bookingText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
