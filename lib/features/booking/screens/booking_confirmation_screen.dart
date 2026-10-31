import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'choose_walk_screen.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

const Color confirmationOrange = DojoWalkTheme.primary;
const Color confirmationBackground = DojoWalkTheme.background;
const Color confirmationText = DojoWalkTheme.text;
const Color confirmationMuted = DojoWalkTheme.mutedText;
const Color confirmationBorder = Color(0xFFEFE5DC);

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

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool get _isRegular =>
      widget.walkType == WalkBookingType.regular ||
      widget.schedule['isRegular'] == true;

  bool get _isChooseDates =>
      widget.walkType == WalkBookingType.chooseDates ||
      widget.schedule['isChooseDates'] == true;

  bool get _isImmediate => widget.schedule['isImmediate'] == true;

  String get _planName {
    if (_isRegular) return 'Regular Daily Walk';
    if (_isChooseDates) return 'Choose Dates';
    return 'One-Time Walk';
  }

  String get _displayPlanName {
    if (_isRegular) return _l10n.bookingConfirmationRegularDailyWalk;
    if (_isChooseDates) return _l10n.bookingConfirmationChooseDates;
    return _l10n.bookingConfirmationOneTimeWalk;
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

  String get _dogName =>
      (widget.dogDetails['name'] ??
              widget.dogDetails['petName'] ??
              'Your Dog')
          .toString();

  String get _dogId =>
      (widget.dogDetails['dogId'] ??
              widget.dogDetails['id'] ??
              '')
          .toString()
          .trim();

  String get _addressId =>
      (widget.pickupAddress['addressId'] ??
              widget.pickupAddress['id'] ??
              '')
          .toString()
          .trim();

  List<Map<String, dynamic>> get _walks {
    final raw = widget.schedule['walks'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [
      {
        'time': _isImmediate
            ? 'ASAP'
            : widget.schedule['time'] ?? '',
        'duration': widget.schedule['duration'] ?? 30,
      },
    ];
  }

  List<Map<String, dynamic>> get _dateSchedules {
    final raw = widget.schedule['dateSchedules'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _walksForDay(Map<String, dynamic> day) {
    final raw = day['walks'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    // Compatibility fallback for older date-schedule payloads.
    final time = day['time'];
    if (time != null && time.toString().trim().isNotEmpty) {
      return [
        {
          'time': time,
          'duration': day['duration'] ?? widget.schedule['duration'] ?? 30,
        },
      ];
    }

    return [];
  }

  int _duration(Map<String, dynamic> walk) {
    final value = walk['duration'];

    if (value is num) return value.toInt();

    final match = RegExp(r'\d+').firstMatch(value?.toString() ?? '');

    return match == null ? 30 : int.parse(match.group(0)!);
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();

    if (value is DateTime) return value;

    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) return parsed;

      final parts = value.split('/');

      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date == null) return _l10n.bookingConfirmationDateToBeConfirmed;

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  DateTime? _dateForSchedule() {
    return _parseDate(
      widget.schedule['date'] ??
          widget.schedule['selectedDate'],
    );
  }

  String _addressText() {
    final parts = [
      widget.pickupAddress['flatHouse'],
      widget.pickupAddress['buildingSociety'],
      widget.pickupAddress['address'],
      widget.pickupAddress['area'],
      widget.pickupAddress['landmark'],
      widget.pickupAddress['city'],
      widget.pickupAddress['pincode'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .map((value) => value.toString().trim())
        .toSet()
        .toList();

    return parts.isEmpty
        ? _l10n.bookingConfirmationPickupAddressUnavailable
        : parts.join(', ');
  }

  String _formatTime(dynamic value) {
    final time = (value ?? '').toString().trim();

    if (time.isEmpty) return _l10n.bookingConfirmationTimeToBeConfirmed;

    if (time.toUpperCase() == 'ASAP') {
      return _l10n.bookingConfirmationAsSoonAsPossible;
    }

    return time;
  }

  Map<String, dynamic>? get _summaryWalk {
    if (_isChooseDates && _dateSchedules.isNotEmpty) {
      final firstDayWalks = _walksForDay(_dateSchedules.first);

      if (firstDayWalks.isNotEmpty) {
        return firstDayWalks.first;
      }
    }

    if (_walks.isNotEmpty) return _walks.first;

    return null;
  }

  dynamic get _summaryDate {
    if (_isChooseDates && _dateSchedules.isNotEmpty) {
      return _dateSchedules.first['date'] ??
          _dateSchedules.first['dateFormatted'];
    }

    return widget.schedule['date'] ??
        widget.schedule['selectedDate'];
  }

  String get _summaryDateText {
    if (_isImmediate) return _l10n.bookingConfirmationAsSoonAsPossible;

    if (_isChooseDates && _dateSchedules.length > 1) {
      return _l10n.bookingConfirmationSelectedDates(_dateSchedules.length);
    }

    return _formatDate(_summaryDate);
  }

  String get _summaryTime {
    if (_isImmediate) return _l10n.bookingConfirmationAsSoonAsPossible;

    final walk = _summaryWalk;

    if (walk == null) return _l10n.bookingConfirmationTimeToBeConfirmed;

    return _formatTime(walk['time']);
  }

  String get _summaryDuration {
    final walk = _summaryWalk;

    if (walk == null) return _l10n.bookingConfirmationToBeConfirmed;

    return '${_duration(walk)} ${_l10n.bookingConfirmationMinutes}';
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: confirmationMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                color: confirmationText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: confirmationBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.bookingConfirmationSummaryHeading,
            style: TextStyle(
              color: confirmationMuted,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _dogName,
            style: const TextStyle(
              color: confirmationText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _displayPlanName,
            style: const TextStyle(
              color: confirmationOrange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _summaryLine(_l10n.bookingConfirmationDateLabel, _summaryDateText),
          _summaryLine(_l10n.bookingConfirmationTimeLabel, _summaryTime),
          _summaryLine(_l10n.bookingConfirmationDurationLabel, _summaryDuration),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 7),
            child: Divider(height: 1, color: confirmationBorder),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: confirmationBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: confirmationBorder),
            ),
            child: Text(
              _l10n.bookingConfirmationPriceDisclosure,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: confirmationMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: confirmationBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: confirmationOrange,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: confirmationText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: confirmationMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: confirmationText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walkCard(
    Map<String, dynamic> walk,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confirmationBackground,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}.',
            style: const TextStyle(
              color: confirmationOrange,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(walk['time']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: confirmationText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_duration(walk)} ${_l10n.bookingConfirmationMinutes}',
                  style: const TextStyle(
                    color: confirmationMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    if (_isChooseDates && _dateSchedules.isNotEmpty) {
      return _section(
        title: _l10n.bookingConfirmationSelectedDatesAndWalks,
        icon: Icons.calendar_month_outlined,
        child: Column(
          children: [
            for (final day in _dateSchedules)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: confirmationBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(
                        day['date'] ?? day['dateFormatted'],
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: confirmationText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final walk in _walksForDay(day))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text(
                          '• ${_formatTime(walk['time'])}  ·  '
                          '${_duration(walk)} ${_l10n.bookingConfirmationMinutesShort}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: confirmationText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return _section(
      title: _l10n.bookingConfirmationWalkSchedule,
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoLine(_l10n.bookingConfirmationPlanLabel, _displayPlanName),
          _infoLine(
            _l10n.bookingConfirmationStartDateLabel,
            _isImmediate
                ? 'As soon as possible'
                : _formatDate(_dateForSchedule()),
          ),
          if (_isRegular)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _l10n.bookingConfirmationRecurringNotice,
                style: const TextStyle(
                  color: confirmationMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          for (var i = 0; i < _walks.length; i++)
            _walkCard(_walks[i], i),
        ],
      ),
    );
  }

  bool _validWalk(Map<String, dynamic> walk) {
    final duration = _duration(walk);
    final time = (walk['time'] ?? '').toString().trim();

    if (duration < 20 || duration > 60) {
      return false;
    }

    if (time.isEmpty) return false;

    return true;
  }

  Map<String, dynamic> _cleanWalk(
    Map<String, dynamic> walk,
    int index,
  ) {
    final result = <String, dynamic>{
      'walkNumber': index + 1,
      'time': (walk['time'] ?? '').toString(),
      'duration': _duration(walk),
    };

    if (walk['startHour'] is num) {
      result['startHour'] = (walk['startHour'] as num).toInt();
    }

    if (walk['startMinute'] is num) {
      result['startMinute'] = (walk['startMinute'] as num).toInt();
    }

    return result;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting || _submitted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(_l10n.bookingConfirmationLoginRequired);
      return;
    }

    if (_dogId.isEmpty || _addressId.isEmpty) {
      _showMessage(_l10n.bookingConfirmationMissingDogOrPickup);
      return;
    }

    if (_isChooseDates && _dateSchedules.isEmpty) {
      _showMessage(_l10n.bookingConfirmationSelectAtLeastOneDate);
      return;
    }

    final walks = _walks;

    if (walks.isEmpty) {
      _showMessage(_l10n.bookingConfirmationAddAtLeastOneWalk);
      return;
    }

    if (!_isChooseDates && walks.length > 3) {
      _showMessage(_l10n.bookingConfirmationMaxThreeWalksPerDay);
      return;
    }

    if (!_isChooseDates && walks.any((walk) => !_validWalk(walk))) {
      _showMessage(_l10n.bookingConfirmationCheckWalkTimeDuration);
      return;
    }

    if (_isChooseDates) {
      for (final day in _dateSchedules) {
        final date = _parseDate(
          day['date'] ?? day['dateFormatted'],
        );
        final dayWalks = _walksForDay(day);

        if (date == null ||
            dayWalks.isEmpty ||
            dayWalks.length > 3 ||
            dayWalks.any((walk) => !_validWalk(walk))) {
          _showMessage(
            _l10n.bookingConfirmationCheckDateSchedules,
          );
          return;
        }
      }
    }

    final selectedDate = _dateForSchedule();

    if (!_isImmediate &&
        !_isChooseDates &&
        selectedDate == null) {
      _showMessage(_l10n.bookingConfirmationValidWalkDate);
      return;
    }

    setState(() => _isSubmitting = true);

    // Error stage helps identify the operation that fails.
    String currentStage = 'Starting booking';

    try {
      final firestore = FirebaseFirestore.instance;

      // Stage 1: Read the selected dog.
      currentStage = 'Reading selected dog';

      debugPrint('DOJO WALK: $currentStage');

      final petSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(_dogId)
          .get();

      if (!petSnapshot.exists) {
        throw Exception(
          'The selected dog was not found. Please select your dog again.',
        );
      }

      final savedDog = petSnapshot.data() ?? <String, dynamic>{};

      final bookingRef = firestore.collection('bookings').doc();

      final primaryWalks = _isChooseDates
          ? _walksForDay(_dateSchedules.first)
          : walks;

      if (primaryWalks.isEmpty || primaryWalks.length > 3) {
        throw Exception(
          'The booking must contain between one and three walks per day.',
        );
      }

      final firstDate = _isChooseDates
          ? _parseDate(
              _dateSchedules.first['date'] ??
                  _dateSchedules.first['dateFormatted'],
            )
          : selectedDate;

      if (!_isImmediate && firstDate == null) {
        throw Exception('A valid booking date is required.');
      }

      final primaryWalkSchedules =
          primaryWalks.asMap().entries.map((entry) {
        return _cleanWalk(entry.value, entry.key);
      }).toList();

      final addressData =
          Map<String, dynamic>.from(widget.pickupAddress);

      final bookingData = <String, dynamic>{
        'bookingId': bookingRef.id,
        'customerId': user.uid,
        'walkType': 'scheduled',
        'bookingPlan': _bookingPlan,
        'serviceType': _serviceType,
        'serviceName': _planName,
        'petName': _dogName,
        'dogId': _dogId,
        'petDetails': {
          ...savedDog,
          'dogId': _dogId,
          'name': _dogName,
        },
        'pickupAddressId': _addressId,
        'pickupAddress': addressData,
        'scheduledAt': Timestamp.fromDate(
          _isImmediate ? DateTime.now() : firstDate!,
        ),
        'duration': '${_duration(primaryWalks.first)} minutes',
        'preferredTime': _isImmediate
            ? 'ASAP'
            : (primaryWalks.first['time'] ?? '').toString(),
        'walkCount': primaryWalks.length,
        'walkSchedules': primaryWalkSchedules,
        'status': 'pending',
        'walkerId': null,
        'cancelRequest': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_isRegular) {
        bookingData.addAll({
          'frequency': 'daily',
          'walksPerWeek': 7,
          'walksPerDay': primaryWalks.length,
          'planStatus': 'pending_confirmation',
          'dailyWalkTemplate': primaryWalkSchedules,
        });
      }

      if (_isChooseDates) {
        bookingData.addAll({
          'walksPerDay': primaryWalks.length,
          'selectedDates': _dateSchedules.map((day) {
            final date = _parseDate(
              day['date'] ?? day['dateFormatted'],
            );

            return date == null ? '' : _dateKey(date);
          }).toList(),
          'dateSchedules': _dateSchedules.map((day) {
            final date = _parseDate(
              day['date'] ?? day['dateFormatted'],
            );

            return <String, dynamic>{
              if (date != null) 'date': Timestamp.fromDate(date),
              'walks': _walksForDay(day).asMap().entries.map((entry) {
                return _cleanWalk(entry.value, entry.key);
              }).toList(),
            };
          }).toList(),
        });
      }

      // Stage 2: Write the booking document.
      currentStage = 'Saving booking document';

      debugPrint('DOJO WALK: $currentStage');
      debugPrint('DOJO WALK: bookingPlan=$_bookingPlan');
      debugPrint('DOJO WALK: serviceType=$_serviceType');
      debugPrint('DOJO WALK: walkCount=${primaryWalks.length}');

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          title: Text(_l10n.bookingConfirmationRequestReceived),
          content: Text(
            '${_l10n.bookingConfirmationRequestSaved}\n\n'
            '${_l10n.bookingConfirmationBookingId}:\n${bookingRef.id}\n\n'
            '${_l10n.bookingConfirmationTeamWillConfirm}',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: confirmationOrange,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
              },
              child: Text(_l10n.bookingConfirmationDone),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('DOJO WALK booking failed at: $currentStage');
      debugPrint('DOJO WALK booking error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      _showMessage(_l10n.continueFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: confirmationText,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: confirmationBackground,
      appBar: AppBar(
        title: Text(_l10n.bookingConfirmationReviewTitle),
        backgroundColor: confirmationBackground,
        foregroundColor: confirmationText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  _buildSummaryCard(),
                  _section(
                    title: _l10n.bookingConfirmationDogDetails,
                    icon: Icons.pets,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoLine(_l10n.bookingConfirmationNameLabel, _dogName),
                        _infoLine(
                          _l10n.bookingConfirmationBreedLabel,
                          (widget.dogDetails['breed'] ??
                                  _l10n.bookingConfirmationNotSpecified)
                              .toString(),
                        ),
                        _infoLine(
                          _l10n.bookingConfirmationGenderLabel,
                          (widget.dogDetails['gender'] ??
                                  _l10n.bookingConfirmationNotSpecified)
                              .toString(),
                        ),
                      ],
                    ),
                  ),
                  _buildScheduleSection(),
                  _section(
                    title: _l10n.bookingConfirmationPickupLocation,
                    icon: Icons.location_on_outlined,
                    child: Text(
                      _addressText(),
                      style: const TextStyle(
                        height: 1.5,
                        color: confirmationText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: confirmationBorder),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting || _submitted
                      ? null
                      : _submitBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: confirmationOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _l10n.bookingConfirmationSubmitRequest,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
