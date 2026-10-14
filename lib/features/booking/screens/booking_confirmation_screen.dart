import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/walk_pricing_service.dart';
import 'choose_walk_screen.dart';

const Color confirmationOrange = Color(0xFFFF7900);
const Color confirmationBackground = Color(0xFFFFFAF5);
const Color confirmationText = Color(0xFF242424);
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

  bool get _isChooseDates =>
      widget.walkType == WalkBookingType.chooseDates ||
      widget.schedule['isChooseDates'] == true;

  bool get _isImmediate => widget.schedule['isImmediate'] == true;

  String get _planName {
    if (_isRegular) return 'Regular Daily Walk';
    if (_isChooseDates) return 'Choose Dates';
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

  String get _dogName =>
      (widget.dogDetails['name'] ??
              widget.dogDetails['petName'] ??
              'Your Dog')
          .toString();

  String get _dogId =>
      (widget.dogDetails['dogId'] ??
              widget.dogDetails['id'] ??
              '')
          .toString();

  String get _addressId =>
      (widget.pickupAddress['addressId'] ??
              widget.pickupAddress['id'] ??
              '')
          .toString();

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

  int _duration(Map<String, dynamic> walk) {
    final value = walk['duration'];

    if (value is num) return value.toInt();

    final match = RegExp(r'\d+').firstMatch(value?.toString() ?? '');

    return match == null ? 30 : int.parse(match.group(0)!);
  }

  // Price हमेशा approved WalkPricingService से निकलेगी।
  // Schedule में भेजी गई price पर भरोसा नहीं किया जाएगा।
  double? _price(Map<String, dynamic> walk) {
    return WalkPricingService.priceForDuration(_duration(walk))
        ?.toDouble();
  }

  double? _totalForWalks(List<Map<String, dynamic>> walks) {
    if (walks.isEmpty) return null;

    double total = 0;

    for (final walk in walks) {
      final price = _price(walk);

      if (price == null) return null;

      total += price;
    }

    return total;
  }

  String _money(double? amount) {
    if (amount == null) return 'Price to be confirmed';

    return '₹${amount.toStringAsFixed(
      amount == amount.roundToDouble() ? 0 : 2,
    )}';
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

    if (date == null) return 'Date to be confirmed';

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
        ? 'Pickup address not available'
        : parts.join(', ');
  }

  String _formatTime(dynamic value) {
    final time = (value ?? '').toString().trim();

    if (time.isEmpty) return 'Time to be confirmed';

    if (time.toUpperCase() == 'ASAP') {
      return 'As soon as possible';
    }

    return time;
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
        border: Border.all(
          color: const Color(0xFFF0E8E1),
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
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
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
            width: 105,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: confirmationOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 11),
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
                const SizedBox(height: 4),
                Text(
                  '${_duration(walk)} minutes',
                  style: const TextStyle(
                    color: confirmationMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _money(_price(walk)),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: confirmationText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _walksForDay(
    Map<String, dynamic> day,
  ) {
    final raw = day['walks'];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Widget _buildScheduleSection() {
    if (_isChooseDates && _dateSchedules.isNotEmpty) {
      return _section(
        title: 'Selected Dates & Walks',
        icon: Icons.calendar_month_outlined,
        child: Column(
          children: [
            for (final day in _dateSchedules)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: confirmationBackground,
                  borderRadius: BorderRadius.circular(12),
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
                          '${_duration(walk)} min  ·  '
                          '${_money(_price(walk))}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    Text(
                      'Daily total: '
                      '${_money(_totalForWalks(_walksForDay(day)))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: confirmationOrange,
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
      title: 'Walk Schedule',
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoLine('Plan', _planName),
          _infoLine(
            'Start date',
            _isImmediate
                ? 'As soon as possible'
                : _formatDate(_dateForSchedule()),
          ),
          if (_isRegular)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'This plan repeats daily, including Sundays. '
                'Any days off will be coordinated later with support.',
                style: TextStyle(
                  color: confirmationMuted,
                  fontSize: 12,
                ),
              ),
            ),
          for (var i = 0; i < _walks.length; i++)
            _walkCard(_walks[i], i),
          if (_isRegular)
            _infoLine(
              'Daily total',
              _money(_totalForWalks(_walks)),
            ),
        ],
      ),
    );
  }

  bool _validWalk(Map<String, dynamic> walk) {
    final duration = _duration(walk);
    final time = (walk['time'] ?? '').toString().trim();

    if (![20, 30, 45, 60].contains(duration)) {
      return false;
    }

    if (time.isEmpty) return false;

    return true;
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting || _submitted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in before submitting your booking.');
      return;
    }

    if (_dogId.isEmpty || _addressId.isEmpty) {
      _showMessage('Dog details or pickup address are missing.');
      return;
    }

    if (_isChooseDates && _dateSchedules.isEmpty) {
      _showMessage('Please select at least one booking date.');
      return;
    }

    final walks = _walks;

    if (walks.isEmpty) {
      _showMessage('Please add at least one walk.');
      return;
    }

    if (!_isChooseDates && walks.length > 3) {
      _showMessage('A maximum of three walks per day is supported.');
      return;
    }

    if (!_isChooseDates && walks.any((walk) => !_validWalk(walk))) {
      _showMessage(
        'Please check every walk time and duration.',
      );
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
            'Please check each selected date and its walk schedule.',
          );
          return;
        }
      }
    }

    final selectedDate = _dateForSchedule();

    if (!_isImmediate &&
        !_isChooseDates &&
        selectedDate == null) {
      _showMessage('Please select a valid walk date.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;

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

      final savedDog =
          petSnapshot.data() ?? <String, dynamic>{};

      final bookingRef = firestore
          .collection('bookings')
          .doc();

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
        final walk = entry.value;
        final price = _price(walk);

        return <String, dynamic>{
          'walkNumber': entry.key + 1,
          'time': (walk['time'] ?? '').toString(),
          'duration': _duration(walk),
          if (walk['startHour'] is num)
            'startHour': (walk['startHour'] as num).toInt(),
          if (walk['startMinute'] is num)
            'startMinute': (walk['startMinute'] as num).toInt(),
          if (price != null) 'price': price,
        };
      }).toList();

      // Preserve the address fields and any coordinates supplied by
      // the saved-address selection screen.
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

          // The request still needs confirmation by the DOJO WALK team.
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

            return date == null
                ? ''
                : '${date.year.toString().padLeft(4, '0')}-'
                    '${date.month.toString().padLeft(2, '0')}-'
                    '${date.day.toString().padLeft(2, '0')}';
          }).toList(),
          'dateSchedules': _dateSchedules.map((day) {
            final date = _parseDate(
              day['date'] ?? day['dateFormatted'],
            );

            return <String, dynamic>{
              if (date != null)
                'date': Timestamp.fromDate(date),
              'walks': _walksForDay(day).asMap().entries.map((entry) {
                final walk = entry.value;
                final price = _price(walk);

                return <String, dynamic>{
                  'walkNumber': entry.key + 1,
                  'time': (walk['time'] ?? '').toString(),
                  'duration': _duration(walk),
                  if (walk['startHour'] is num)
                    'startHour': (walk['startHour'] as num).toInt(),
                  if (walk['startMinute'] is num)
                    'startMinute': (walk['startMinute'] as num).toInt(),
                  if (price != null) 'price': price,
                };
              }).toList(),
            };
          }).toList(),
        });
      }

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
          title: const Text('Request Received!'),
          content: Text(
            'Your $_planName request has been saved.\n\n'
            'Booking ID:\n${bookingRef.id}\n\n'
            'The DOJO WALK team will confirm walker availability '
            'and any unfinalized pricing.',
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
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      _showMessage(
        'Booking could not be saved.\n${error.toString()}',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: confirmationText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _isChooseDates
        ? _totalForWalks(
            _dateSchedules
                .expand((day) => _walksForDay(day))
                .toList(),
          )
        : _totalForWalks(_walks);

    return Scaffold(
      backgroundColor: confirmationBackground,
      appBar: AppBar(
        title: const Text('Review Your Booking'),
        backgroundColor: confirmationBackground,
        foregroundColor: confirmationText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: confirmationOrange.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          color: confirmationOrange,
                          size: 26,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please review your dog, pickup location '
                            'and walk schedule before submitting.',
                            style: TextStyle(
                              color: confirmationText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title: 'Dog Details',
                    icon: Icons.pets,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoLine('Name', _dogName),
                        _infoLine(
                          'Breed',
                          (widget.dogDetails['breed'] ??
                                  'Not specified')
                              .toString(),
                        ),
                        _infoLine(
                          'Gender',
                          (widget.dogDetails['gender'] ??
                                  'Not specified')
                              .toString(),
                        ),
                      ],
                    ),
                  ),
                  _buildScheduleSection(),
                  _section(
                    title: 'Pickup Location',
                    icon: Icons.location_on_outlined,
                    child: Text(
                      _addressText(),
                      style: const TextStyle(
                        height: 1.5,
                        color: confirmationText,
                      ),
                    ),
                  ),
                  _section(
                    title: 'Price Summary',
                    icon: Icons.currency_rupee,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoLine(
                          _isChooseDates
                              ? 'Selected dates total'
                              : _isRegular
                                  ? 'Daily total'
                                  : 'Total',
                          _money(total),
                        ),
                        const Text(
                          '₹149 applies to a 30-minute walk only. '
                          'Other durations and final charges require '
                          'confirmation. Walker availability is not '
                          'guaranteed until the team confirms.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: confirmationMuted,
                          ),
                        ),
                      ],
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
                  top: BorderSide(
                    color: Color(0xFFEFE7E0),
                  ),
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
                      : const Text(
                          'Submit Booking Request',
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
