import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

const Color bookingsOrange = DojoWalkTheme.primary;
const Color bookingsBackground = DojoWalkTheme.background;
const Color bookingsText = DojoWalkTheme.text;
const Color bookingsMuted = DojoWalkTheme.mutedText;
const Color bookingsBorder = Color(0xFFF0E9E2);

String _t(String en, String hi, String bn) {
  switch (appLocale.value.languageCode) {
    case 'hi':
      return hi;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

String _text(
  dynamic value, {
  String? fallback,
}) {
  if (value == null || value.toString().trim().isEmpty) {
    return fallback ??
        _t(
          'Not provided',
          'जानकारी उपलब्ध नहीं',
          'তথ্য দেওয়া নেই',
        );
  }

  if (value is List) return value.join(', ');

  return value.toString().trim();
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

Map<String, dynamic> _petDetails(
  Map<String, dynamic> data,
) {
  return _map(data['petDetails']);
}

String _status(Map<String, dynamic> data) {
  return _text(
    data['status'],
    fallback: 'pending',
  ).toLowerCase();
}

bool _isCancelled(String status) {
  return status == 'cancelled' || status == 'canceled';
}

bool _isUpcoming(String status) {
  return [
    'pending',
    'finding_walker',
    'walker_assigned',
    'walker_arriving',
    'confirmed',
    'assigned',
    'accepted',
    'in_progress',
    'in progress',
  ].contains(status);
}

String _statusText(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context);
  switch (status.toLowerCase()) {
    case 'pending':
      return l10n.bookingStatusPending;
    case 'finding_walker':
      return l10n.bookingStatusFindingWalker;
    case 'walker_assigned':
    case 'assigned':
      return l10n.bookingStatusWalkerAssigned;
    case 'walker_arriving':
      return l10n.bookingStatusWalkerArriving;
    case 'confirmed':
    case 'accepted':
      return l10n.bookingStatusConfirmed;
    case 'in_progress':
    case 'in progress':
      return l10n.bookingStatusInProgress;
    case 'completed':
      return l10n.bookingStatusCompleted;
    case 'cancelled':
    case 'canceled':
      return l10n.bookingStatusCancelled;
    default:
      return status.replaceAll('_', ' ');
  }
}

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();

  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime(2000);
  }

  return DateTime(2000);
}

String _formatDate(DateTime date) {
  if (date.year <= 2000) {
    return _t('Not provided', 'जानकारी उपलब्ध नहीं', 'তথ্য দেওয়া নেই');
  }

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

String _formatTime(DateTime date) {
  if (date.year <= 2000) {
    return _t(
      'Not provided',
      'जानकारी उपलब्ध नहीं',
      'তথ্য দেওয়া নেই',
    );
  }

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute ${date.hour >= 12 ? _t('PM', 'PM', 'PM') : _t('AM', 'AM', 'AM')}';
}

String _duration(Map<String, dynamic> data) {
  final value = data['duration'];

  if (value == null || value.toString().trim().isEmpty) {
    return _t(
      'Not provided',
      'जानकारी उपलब्ध नहीं',
      'তথ্য দেওয়া নেই',
    );
  }

  final duration = value.toString().trim();

  if (RegExp(r'^\d+$').hasMatch(duration)) {
    return '$duration ${_t('minutes', 'मिनट', 'মিনিট')}';
  }

  return duration;
}

String _plan(Map<String, dynamic> data) {
  final plan = _text(
    data['bookingPlan'],
    fallback: '',
  ).toLowerCase();

  final service = _text(
    data['serviceType'],
    fallback: '',
  ).toLowerCase();

  if (plan == 'regular' || service == 'regular_walk') {
    return _t('Regular Walk', 'रेगুলर वॉक', 'নিয়মিত ওয়াক');
  }

  if (plan == 'customize' || service == 'custom_walk') {
    return _t('Customized Walk', 'कस्टম वॉक', 'কাস্টম ওয়াক');
  }

  return _t('One-Time Walk', 'एक बार की वॉक', 'একবারের ওয়াক');
}

String _address(dynamic value) {
  final address = _map(value);

  return [
    address['address'],
    address['flatHouse'],
    address['buildingSociety'],
    address['area'],
    address['landmark'],
    address['city'],
    address['pincode'],
  ]
      .where(
        (v) => v != null && v.toString().trim().isNotEmpty,
      )
      .map((v) => v.toString().trim())
      .toSet()
      .join(', ');
}

// ============================================================
// PRICE HELPERS
// ============================================================

String _money(dynamic value) {
  if (value is! num || !value.isFinite || value < 0) {
    return _t('Price to be confirmed', 'कीमत की पुष्टि बाकी है', 'দাম নিশ্চিত করা বাকি');
  }

  return '₹${value.toStringAsFixed(
    value == value.roundToDouble() ? 0 : 2,
  )}';
}

double? _savedWalkPrice(Map<String, dynamic> walk) {
  final value = walk['price'];

  if (value is num && value.isFinite && value >= 0) {
    return value.toDouble();
  }

  return null;
}

double? _savedBookingTotal(Map<String, dynamic> data) {
  final dateSchedules = data['dateSchedules'];

  // Choose Dates: सभी चुनी हुई तारीखों का कुल।
  if (dateSchedules is List && dateSchedules.isNotEmpty) {
    double total = 0;

    for (final dayValue in dateSchedules) {
      final day = _map(dayValue);
      final walks = day['walks'];

      if (walks is! List || walks.isEmpty) {
        return null;
      }

      for (final walkValue in walks) {
        final walk = _map(walkValue);
        final price = _savedWalkPrice(walk);

        if (price == null) return null;

        total += price;
      }
    }

    return total;
  }

  // One-Time और Regular: सेव की गई walkSchedules कीमतें।
  final schedules = data['walkSchedules'];

  if (schedules is List && schedules.isNotEmpty) {
    double total = 0;

    for (final walkValue in schedules) {
      final walk = _map(walkValue);
      final price = _savedWalkPrice(walk);

      if (price == null) return null;

      total += price;
    }

    return total;
  }

  // पुराने records में यदि कुल राशि सेव है, तो उसका उपयोग करें।
  final savedTotal = data['totalAmount'];

  if (savedTotal is num &&
      savedTotal.isFinite &&
      savedTotal >= 0) {
    return savedTotal.toDouble();
  }

  return null;
}

double? _savedAdditionalCharges(
  Map<String, dynamic> data,
) {
  final value = data['additionalCharges'];

  if (value is num && value.isFinite && value >= 0) {
    return value.toDouble();
  }

  return null;
}

double? _grandTotal(Map<String, dynamic> data) {
  final walkTotal = _savedBookingTotal(data);

  if (walkTotal == null) return null;

  final extraCharges = _savedAdditionalCharges(data) ?? 0;

  return walkTotal + extraCharges;
}

// ============================================================
// MY BOOKINGS SCREEN
// ============================================================

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: bookingsBackground,
          appBar: AppBar(
            backgroundColor: bookingsBackground,
            automaticallyImplyLeading: false,
            elevation: 0,
            title: Text(
              AppLocalizations.of(context).myBookings,
              style: const TextStyle(
                color: bookingsText,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, auth) {
                      if (auth.connectionState ==
                              ConnectionState.waiting &&
                          !auth.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: bookingsOrange,
                          ),
                        );
                      }

                      final user = auth.data;

                      if (user == null) {
                        return _message(
                          Icons.person_outline,
                          AppLocalizations.of(context).bookingsLoginRequired,
                          AppLocalizations.of(context).bookingsLoginPrompt,
                        );
                      }

                      return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .where(
                              'customerId',
                              isEqualTo: user.uid,
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _message(
                              Icons.error_outline,
                              AppLocalizations.of(context).bookingsLoadErrorTitle,
                              AppLocalizations.of(context).bookingsConnectionPermissionError,
                              action: TextButton(
                                onPressed: () => setState(() {}),
                                child: Text(
                                  AppLocalizations.of(context).bookingsRefresh,
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: bookingsOrange,
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];

                          final bookings = docs.where((doc) {
                            final status = _status(doc.data());

                            switch (_selectedFilter) {
                              case 1:
                                return _isUpcoming(status);
                              case 2:
                                return status == 'completed';
                              case 3:
                                return _isCancelled(status);
                              default:
                                return true;
                            }
                          }).toList();

                          bookings.sort((a, b) {
                            return _date(b.data()['scheduledAt'])
                                .compareTo(
                              _date(a.data()['scheduledAt']),
                            );
                          });

                          if (bookings.isEmpty) {
                            return _message(
                              Icons.receipt_long,
                              AppLocalizations.of(context).bookingsEmptyTitle,
                              AppLocalizations.of(context).bookingsEmptyBody,
                            );
                          }

                          return RefreshIndicator(
                            color: bookingsOrange,
                            onRefresh: () async {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .where(
                                    'customerId',
                                    isEqualTo: user.uid,
                                  )
                                  .get(
                                    const GetOptions(
                                      source: Source.server,
                                    ),
                                  );
                            },
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: bookings.length,
                              itemBuilder: (context, index) {
                                final doc = bookings[index];

                                return _BookingCard(
                                  key: ValueKey(doc.id),
                                  documentId: doc.id,
                                  data: doc.data(),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    final filters = [
      AppLocalizations.of(context).bookingsFilterAll,
      AppLocalizations.of(context).bookingsFilterUpcoming,
      AppLocalizations.of(context).bookingsFilterCompleted,
      AppLocalizations.of(context).bookingsFilterCancelled,
    ];

    return SizedBox(
      height: 55,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;

          return ChoiceChip(
            label: Text(filters[index]),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedFilter = index);
            },
            selectedColor: bookingsOrange,
            backgroundColor: Colors.white,
            showCheckmark: false,
            side: BorderSide(
              color: selected
                  ? bookingsOrange
                  : const Color(0xFFEAEAEA),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : bookingsText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String message, {
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: bookingsOrange,
              size: 54,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: bookingsText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: bookingsMuted,
                height: 1.5,
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOOKING CARD
// ============================================================

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    super.key,
    required this.documentId,
    required this.data,
  });

  final String documentId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final pet = _petDetails(data);
    final status = _status(data);
    final address = _address(data['pickupAddress']);
    final total = _grandTotal(data);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: bookingsBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 49,
                    width: 49,
                    decoration: BoxDecoration(
                      color: bookingsOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: bookingsOrange,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(
                            data['serviceName'],
                            fallback: AppLocalizations.of(context).bookingDogWalking,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: bookingsText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppLocalizations.of(context).bookingDogLabel}: '
                          '${_text(
                            pet['name'] ?? data['petName'],
                            fallback: AppLocalizations.of(context).bookingYourDog,
                          )}',
                          style: const TextStyle(
                            color: bookingsMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_plan(data)} · ${_duration(data)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: bookingsMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(context, status),
                ],
              ),
              const Divider(height: 28),
              _row(
                Icons.calendar_month_outlined,
                AppLocalizations.of(context).bookingDateTime,
                '${_formatDate(_date(data['scheduledAt']))} · '
                '${_text(
                  data['preferredTime'],
                  fallback: _formatTime(_date(data['scheduledAt'])),
                )}',
              ),
              const SizedBox(height: 12),
              _row(
                Icons.confirmation_number_outlined,
                AppLocalizations.of(context).bookingIdLabel,
                _text(
                  data['bookingId'],
                  fallback: documentId,
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 12),
                _row(
                  Icons.location_on_outlined,
                  AppLocalizations.of(context).bookingPickup,
                  address,
                ),
              ],
              const SizedBox(height: 15),

              // PRICE SUMMARY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bookingsBackground,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: bookingsBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).bookingTotalAmountUpper,
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w700,
                              color: bookingsMuted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _money(total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: bookingsOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (total == null)
                      const Icon(
                        Icons.info_outline,
                        color: bookingsMuted,
                        size: 21,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openDetails(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bookingsOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).bookingViewDetails,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailsScreen(
          documentId: documentId,
          initialData: data,
        ),
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: bookingsOrange,
          size: 19,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: bookingsMuted,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: bookingsText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _statusBadge(BuildContext context, String status) {
  final color = status == 'completed'
      ? Colors.green
      : _isCancelled(status)
          ? Colors.red
          : bookingsOrange;

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 9,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      _statusText(context, status).toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

// ============================================================
// BOOKING DETAILS SCREEN
// ============================================================

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({
    super.key,
    required this.documentId,
    required this.initialData,
  });

  final String documentId;
  final Map<String, dynamic> initialData;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context).bookingLoginToView,
          ),
        ),
      );
    }

    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .doc(documentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: bookingsBackground,
                appBar: AppBar(
                  title: Text(
                    AppLocalizations.of(context).bookingsDetailsTitle,
                  ),
                ),
                body: Center(
                  child: Text(
                    AppLocalizations.of(context).bookingDetailsLoadFailure,
                  ),
                ),
              );
            }

            final data = snapshot.data?.data() ?? initialData;

            if (data['customerId'] != user.uid) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    AppLocalizations.of(context).bookingsDetailsTitle,
                  ),
                ),
                body: Center(
                  child: Text(
                    AppLocalizations.of(context).bookingDetailsUnavailable,
                  ),
                ),
              );
            }

            final pet = _petDetails(data);
            final address = _address(data['pickupAddress']);
            final plan = _plan(data);

            final regular = data['bookingPlan'] == 'regular' ||
                data['serviceType'] == 'regular_walk';

            final total = _savedBookingTotal(data);
            final extraCharges = _savedAdditionalCharges(data);
            final grandTotal = _grandTotal(data);

            final cancelRequest = _map(data['cancelRequest']);

            final cancelStatus = data['cancelRequest'] == null
                ? 'none'
                : _text(
                    cancelRequest['status'],
                    fallback: 'pending',
                  ).toLowerCase();

            return Scaffold(
              backgroundColor: bookingsBackground,
              appBar: AppBar(
                backgroundColor: bookingsBackground,
                foregroundColor: bookingsText,
                elevation: 0,
                title: Text(
                  _t(
                    'Booking Details',
                    'बुकिंग की जानकारी',
                    'বুকিংয়ের বিবরণ',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  _section(
                    AppLocalizations.of(context).bookingSummary,
                    [
                      _detail(
                        AppLocalizations.of(context).bookingIdLabel,
                        _text(
                          data['bookingId'],
                          fallback: documentId,
                        ),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingPlanLabel,
                        plan,
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingDurationLabel,
                        _duration(data),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingDateLabel,
                        _formatDate(_date(data['scheduledAt'])),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingPreferredTime,
                        _text(
                          data['preferredTime'],
                          fallback: _formatTime(
                            _date(data['scheduledAt']),
                          ),
                        ),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingStatusLabel,
                        _statusText(context, _status(data)),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingNumberOfWalks,
                        _text(data['walkCount']),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // PRICE DETAILS
                  _section(
                    AppLocalizations.of(context).bookingPriceDetails,
                    [
                      _detail(
                        AppLocalizations.of(context).bookingWalkCharges,
                        _money(total),
                      ),
                      if (extraCharges != null && extraCharges > 0)
                        _detail(
                          AppLocalizations.of(context).bookingAdditionalCharges,
                          _money(extraCharges),
                        ),
                      const Divider(height: 24),
                      _priceDetail(
                        AppLocalizations.of(context).bookingTotalAmount,
                        _money(grandTotal),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        AppLocalizations.of(context).bookingPriceDisclosure,
                        style: const TextStyle(
                          color: bookingsMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _section(
                    AppLocalizations.of(context).bookingDogDetails,
                    [
                      _detail(
                        AppLocalizations.of(context).bookingDogName,
                        _text(pet['name'] ?? data['petName']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingDogId,
                        _text(data['dogId']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingBreed,
                        _text(pet['breed']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingAge,
                        _age(pet['age'] ?? pet['dob']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingSize,
                        _text(pet['size']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingGender,
                        _text(pet['gender']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingBehaviour,
                        _text(pet['behaviour']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingSpecialCare,
                        _text(pet['specialCare']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingNotes,
                        _text(pet['notes']),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _section(
                    AppLocalizations.of(context).bookingPickupAddress,
                    [
                      _detail(
                        AppLocalizations.of(context).bookingAddressType,
                        _text(_map(data['pickupAddress'])['label']),
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingFullAddress,
                        address.isEmpty
                            ? _t(
                                'Not provided',
                                'जानकारी उपलब्ध नहीं',
                                'তথ্য দেওয়া নেই',
                              )
                            : address,
                      ),
                      _detail(
                        AppLocalizations.of(context).bookingLandmark,
                        _text(
                          _map(data['pickupAddress'])['landmark'],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _section(
                    AppLocalizations.of(context).bookingAssignedWalker,
                    [
                      _detail(
                        AppLocalizations.of(context).bookingWalkerId,
                        _text(
                          data['walkerId'],
                          fallback: AppLocalizations.of(context).bookingNotAssigned,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).bookingWalkerInfoDisclosure,
                        style: const TextStyle(
                          color: bookingsMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                  if (regular) ...[
                    const SizedBox(height: 14),
                    _section(
                      AppLocalizations.of(context).bookingRegularWalkPlan,
                      [
                        _detail(
                          AppLocalizations.of(context).bookingFrequency,
                          _text(data['frequency']),
                        ),
                        _detail(
                          AppLocalizations.of(context).bookingWalksPerWeek,
                          _text(data['walksPerWeek']),
                        ),
                        _detail(
                          AppLocalizations.of(context).bookingWalksPerDay,
                          _text(data['walksPerDay']),
                        ),
                      ],
                    ),
                  ],

                  if (data['walkSchedules'] is List) ...[
                    const SizedBox(height: 14),
                    _section(
                      AppLocalizations.of(context).bookingWalkSchedule,
                      _scheduleDetails(data['walkSchedules']),
                    ),
                  ],

                  if (data['dateSchedules'] is List) ...[
                    const SizedBox(height: 14),
                    _section(
                      AppLocalizations.of(context).bookingSelectedDates,
                      _dateScheduleDetails(data['dateSchedules']),
                    ),
                  ],

                  const SizedBox(height: 14),

                  _section(
                    AppLocalizations.of(context).bookingCancelRequestSection,
                    [
                      _detail(
                        AppLocalizations.of(context).bookingRequestStatus,
                        _cancelStatusText(context, cancelStatus),
                      ),
                      if (_isCancelled(_status(data)))
                        Text(
                          AppLocalizations.of(context).bookingAlreadyCancelled,
                        )
                      else if (_status(data) == 'completed')
                        Text(
                          AppLocalizations.of(context).bookingCompletedCannotCancel,
                        )
                      else if (cancelStatus == 'pending')
                        Text(
                          AppLocalizations.of(context).bookingCancellationAwaitingReview,
                        )
                      else if (cancelStatus == 'approved')
                        Text(
                          AppLocalizations.of(context).bookingCancellationApproved,
                        )
                      else if (cancelStatus == 'rejected')
                        Text(
                          AppLocalizations.of(context).bookingCancellationRejected,
                        )
                      else if (_isUpcoming(_status(data)))
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(
                              AppLocalizations.of(context).bookingRequestCancellation,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                            onPressed: () => _requestCancellation(
                              context,
                              documentId,
                              user.uid,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _section(
                    AppLocalizations.of(context).bookingHelpSupport,
                    [
                      Text(
                        AppLocalizations.of(context).bookingHelpSupportDisclosure,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// PRICE DETAIL ROW
// ============================================================

Widget _priceDetail(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: bookingsText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: bookingsOrange,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

// ============================================================
// CANCELLATION
// ============================================================

String _cancelStatusText(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context);
  switch (status) {
    case 'none':
      return l10n.bookingStatusNotRequested;
    case 'pending':
      return l10n.bookingStatusPending;
    case 'approved':
      return l10n.bookingStatusApproved;
    case 'rejected':
      return l10n.bookingStatusRejected;
    default:
      return status;
  }
}

Future<void> _requestCancellation(
  BuildContext context,
  String documentId,
  String userId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        AppLocalizations.of(context).bookingCancelConfirmTitle,
      ),
      content: Text(
        AppLocalizations.of(context).bookingCancelConfirmBody,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            AppLocalizations.of(context).bookingGoBack,
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            AppLocalizations.of(context).bookingConfirm,
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;
  final l10n = AppLocalizations.of(context);

  try {
    final ref = FirebaseFirestore.instance
        .collection('bookings')
        .doc(documentId);

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception(l10n.bookingNotFound);
        }

        final current = snapshot.data() ?? <String, dynamic>{};

        if (current['customerId'] != userId) {
          throw Exception(l10n.cannotChangeBooking);
        }

        final status = _status(current);

        if (!_isUpcoming(status)) {
          throw Exception(
            l10n.cancellationNotAvailable,
          );
        }

        if (current['cancelRequest'] != null) {
          throw Exception(
            l10n.cancellationAlreadyRequested,
          );
        }

        transaction.update(ref, {
          'cancelRequest': {
            'status': 'pending',
            'requestedBy': 'customer',
            'customerId': userId,
            'requestedAt': FieldValue.serverTimestamp(),
          },
        });
      },
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).bookingCancelSubmitted,
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).bookingRequestFailed}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }
}

// ============================================================
// SCHEDULE DETAILS
// ============================================================

List<Widget> _scheduleDetails(dynamic value) {
  if (value is! List || value.isEmpty) {
    return [
      _detail(
        _t('Schedule', 'शेड्यूल', 'সময়সূচি'),
        _t(
          'Not provided',
          'जानकारी उपलब्ध नहीं',
          'তথ্য দেওয়া নেই',
        ),
      ),
    ];
  }

  return List<Widget>.generate(value.length, (index) {
    final walk = _map(value[index]);

    return _detail(
      '${_t('Walk', 'वॉक', 'ওয়াক')} ${index + 1}',
      '${_text(walk['time'])} · ${_text(walk['duration'])}',
    );
  });
}

List<Widget> _dateScheduleDetails(dynamic value) {
  if (value is! List || value.isEmpty) {
    return [
      _detail(
        _t('Dates', 'तारीखें', 'তারিখ'),
        _t(
          'Not provided',
          'जानकारी उपलब्ध नहीं',
          'তথ্য দেওয়া নেই',
        ),
      ),
    ];
  }

  final result = <Widget>[];

  for (var i = 0; i < value.length; i++) {
    final day = _map(value[i]);
    final date = _date(day['date']);
    final walks = day['walks'];

    result.add(
      _detail(
        _t('Date', 'तारीख़', 'তারিখ'),
        _formatDate(date),
      ),
    );

    if (walks is List) {
      for (var j = 0; j < walks.length; j++) {
        final walk = _map(walks[j]);

        result.add(
          _detail(
            '${_t('Walk', 'वॉक', 'ওয়াক')} ${j + 1}',
            '${_text(walk['time'])} · '
            '${_text(walk['duration'])} · '
            '${_money(_savedWalkPrice(walk))}',
          ),
        );
      }
    }
  }

  return result;
}

// ============================================================
// AGE
// ============================================================

String _age(dynamic value) {
  if (value is Timestamp) {
    final dob = value.toDate();
    final now = DateTime.now();

    var years = now.year - dob.year;

    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }

    if (years < 0) {
      return _t(
        'Not provided',
        'जानकारी उपलब्ध नहीं',
        'তথ্য দেওয়া নেই',
      );
    }

    if (years == 0) {
      return _t(
        'Less than 1 year',
        '1 साल से कम',
        '১ বছরের কম',
      );
    }

    return '$years ${_t('years', 'साल', 'বছর')}';
  }

  final age = _text(value);

  if (age == _t('Not provided', 'जानकारी उपलब्ध नहीं', 'তথ্য দেওয়া নেই')) return age;

  if (RegExp(r'^\d+$').hasMatch(age)) {
    return '$age ${_t('years', 'साल', 'বছর')}';
  }

  return age;
}

// ============================================================
// REUSABLE DETAILS SECTION
// ============================================================

Widget _section(
  String title,
  List<Widget> children,
) {
  return Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: bookingsBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: bookingsText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Divider(height: 25),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: child,
          ),
        ),
      ],
    ),
  );
}

Widget _detail(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 112,
        child: Text(
          label,
          style: const TextStyle(
            color: bookingsMuted,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: bookingsText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}
