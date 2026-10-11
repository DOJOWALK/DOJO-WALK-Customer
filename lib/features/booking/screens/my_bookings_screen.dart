import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color bookingsOrange = Color(0xFFFF7900);
const Color bookingsBackground = Color(0xFFFFFAF5);
const Color bookingsText = Color(0xFF202020);
const Color bookingsMuted = Color(0xFF777777);

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() =>
      _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedFilter = 0;

  static const List<String> _filters = [
    'All',
    'Upcoming',
    'Completed',
    'Cancelled',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: uid)
        .snapshots();
  }

  bool _isUpcoming(Map<String, dynamic> data) {
    final status = (data['status'] ?? '')
        .toString()
        .toLowerCase();

    return [
      'pending',
      'confirmed',
      'assigned',
      'accepted',
      'in_progress',
    ].contains(status);
  }

  bool _isCompleted(Map<String, dynamic> data) {
    return (data['status'] ?? '')
            .toString()
            .toLowerCase() ==
        'completed';
  }

  bool _isCancelled(Map<String, dynamic> data) {
    return (data['status'] ?? '')
            .toString()
            .toLowerCase() ==
        'cancelled';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filteredBookings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final bookings = docs.where((doc) {
      final data = doc.data();

      switch (_selectedFilter) {
        case 1:
          return _isUpcoming(data);
        case 2:
          return _isCompleted(data);
        case 3:
          return _isCancelled(data);
        default:
          return true;
      }
    }).toList();

    DateTime dateOf(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      final value = doc.data()['scheduledAt'];

      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;

      if (value is String) {
        return DateTime.tryParse(value) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    bookings.sort(
      (a, b) => dateOf(b).compareTo(dateOf(a)),
    );

    return bookings;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bookingsBackground,
      appBar: AppBar(
        backgroundColor: bookingsBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Bookings',
          style: TextStyle(
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
              child: user == null
                  ? _buildMessage(
                      icon: Icons.person_outline_rounded,
                      title: 'Login Required',
                      message:
                          'Please log in to view your bookings.',
                    )
                  : StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                      stream: _bookingStream(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildMessage(
                            icon: Icons.error_outline_rounded,
                            title: 'Could Not Load Bookings',
                            message:
                                'Please check your connection and try again.',
                            action: TextButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: bookingsOrange,
                              ),
                              label: const Text(
                                'Refresh',
                                style: TextStyle(
                                  color: bookingsOrange,
                                  fontWeight: FontWeight.w800,
                                ),
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

                        final docs =
                            snapshot.data?.docs ?? [];

                        final bookings =
                            _filteredBookings(docs);

                        if (bookings.isEmpty) {
                          return _buildEmptyState();
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
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              10,
                              16,
                              24,
                            ),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final doc = bookings[index];

                              return _BookingCard(
                                bookingId: doc.id,
                                data: doc.data(),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 55,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;

          return ChoiceChip(
            label: Text(_filters[index]),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = index;
              });
            },
            selectedColor: bookingsOrange,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? bookingsOrange
                  : const Color(0xFFEAEAEA),
            ),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : bookingsText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final String message;

    switch (_selectedFilter) {
      case 1:
        message = 'Your upcoming walks will appear here.';
        break;
      case 2:
        message = 'Your completed walks will appear here.';
        break;
      case 3:
        message = 'Your cancelled walks will appear here.';
        break;
      default:
        message =
            'Your dog walking bookings will appear here.';
    }

    return _buildMessage(
      icon: Icons.receipt_long_rounded,
      title: 'No Bookings Yet',
      message: message,
      action: null,
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 112,
              width: 112,
              decoration: BoxDecoration(
                color: bookingsOrange.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 54,
                color: bookingsOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: bookingsText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: bookingsMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.bookingId,
    required this.data,
  });

  final String bookingId;
  final Map<String, dynamic> data;

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Schedule not available';

    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final petDetails = data['petDetails'];
    final pet = petDetails is Map
        ? Map<String, dynamic>.from(petDetails)
        : <String, dynamic>{};

    final addressData = data['pickupAddress'];
    final address = addressData is Map
        ? Map<String, dynamic>.from(addressData)
        : <String, dynamic>{};

    final petName = (pet['name'] ??
            data['petName'] ??
            'Your dog')
        .toString();

    final serviceName = (data['serviceName'] ??
            data['serviceType'] ??
            'Dog Walk')
        .toString();

    final status =
        (data['status'] ?? 'pending').toString();

    final statusLower = status.toLowerCase();

    final statusColor = statusLower == 'completed'
        ? Colors.green
        : statusLower == 'cancelled'
            ? Colors.red
            : bookingsOrange;

    final addressText = [
      address['address'],
      address['area'],
      address['city'],
      address['pincode'],
    ]
        .where((part) =>
            part != null &&
            part.toString().trim().isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF0E9E2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: bookingsOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: bookingsOrange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        color: bookingsText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pet: $petName',
                      style: const TextStyle(
                        color: bookingsMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(
            Icons.confirmation_number_outlined,
            'Booking ID',
            (data['bookingId'] ?? bookingId).toString(),
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.schedule_rounded,
            'Schedule',
            _formatDate(data['scheduledAt']),
          ),
          if (addressText.isNotEmpty) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.location_on_outlined,
              'Pickup',
              addressText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: bookingsOrange,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(
              color: bookingsMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
