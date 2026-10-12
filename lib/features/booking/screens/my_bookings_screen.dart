
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
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedFilter = 0;

  static const _filters = [
    'All',
    'Upcoming',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bookingsBackground,
      appBar: AppBar(
        backgroundColor: bookingsBackground,
        automaticallyImplyLeading: false,
        elevation: 0,
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
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, auth) {
                  if (auth.connectionState == ConnectionState.waiting &&
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
                      'Login Required',
                      'Please log in to view your bookings.',
                    );
                  }

                  return StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('customerId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _message(
                          Icons.error_outline,
                          'Could Not Load Bookings',
                          'Please check your connection and Firebase permissions.',
                          action: TextButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Refresh'),
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
                            return status == 'cancelled' ||
                                status == 'canceled';
                          default:
                            return true;
                        }
                      }).toList();

                      bookings.sort((a, b) {
                        return _date(b.data()['scheduledAt'])
                            .compareTo(_date(a.data()['scheduledAt']));
                      });

                      if (bookings.isEmpty) {
                        return _message(
                          Icons.receipt_long,
                          'No Bookings Yet',
                          'Your dog walking bookings will appear here.',
                        );
                      }

                      return RefreshIndicator(
                        color: bookingsOrange,
                        onRefresh: () async {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .where('customerId', isEqualTo: user.uid)
                              .get(const GetOptions(source: Source.server));
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
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
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;
          return ChoiceChip(
            label: Text(_filters[index]),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFilter = index),
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
            Icon(icon, color: bookingsOrange, size: 54),
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
    final plan = _plan(data);
    final address = _address(data['pickupAddress']);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF0E9E2)),
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
                          _text(data['serviceName'], fallback: 'Dog Walking'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: bookingsText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dog: ${_text(pet['name'] ?? data['petName'], fallback: 'Your dog')}',
                          style: const TextStyle(
                            color: bookingsMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$plan · ${_duration(data)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: bookingsMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const Divider(height: 28),
              _row(
                Icons.calendar_month_outlined,
                'Date & Time',
                '${_formatDate(_date(data['scheduledAt']))} · '
                    '${_text(data['preferredTime'], fallback: _formatTime(_date(data['scheduledAt'])))}',
              ),
              const SizedBox(height: 12),
              _row(
                Icons.confirmation_number_outlined,
                'Booking ID',
                _text(data['bookingId'], fallback: documentId),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 12),
                _row(Icons.location_on_outlined, 'Pickup', address),
              ],
              const SizedBox(height: 18),
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
                  child: const Text(
                    'View Booking Details',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: bookingsOrange, size: 19),
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
      return const Scaffold(
        body: Center(child: Text('Please log in to view this booking.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: bookingsBackground,
            appBar: AppBar(title: const Text('Booking Details')),
            body: const Center(
              child: Text('Unable to load booking details.'),
            ),
          );
        }

        final data = snapshot.data?.data() ?? initialData;

        // Do not expose a booking belonging to another customer.
        if (data['customerId'] != user.uid) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Details')),
            body: const Center(child: Text('Booking not available.')),
          );
        }

        final pet = _petDetails(data);
        final status = _status(data);
        final address = _address(data['pickupAddress']);
        final regular = _plan(data) == 'Regular Walk';

        return Scaffold(
          backgroundColor: bookingsBackground,
          appBar: AppBar(
            backgroundColor: bookingsBackground,
            foregroundColor: bookingsText,
            elevation: 0,
            title: const Text(
              'Booking Details',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              _section('Booking Summary', [
                _detail('Booking ID',
                    _text(data['bookingId'], fallback: documentId)),
                _detail('Plan', _plan(data)),
                _detail('Duration', _duration(data)),
                _detail('Date', _formatDate(_date(data['scheduledAt']))),
                _detail(
                  'Preferred Time',
                  _text(data['preferredTime'],
                      fallback: _formatTime(_date(data['scheduledAt']))),
                ),
                _detail('Status', status.toUpperCase()),
                _detail(
                  'Created',
                  _formatDate(_date(data['createdAt'])),
                ),
              ]),
              const SizedBox(height: 14),
              _section('Dog Details', [
                _detail('Dog Name',
                    _text(pet['name'] ?? data['petName'])),
                _detail('Dog ID', _text(data['dogId'])),
                _detail('Breed', _text(pet['breed'])),
                _detail('Age', _age(pet['age'])),
                _detail('Size', _text(pet['size'])),
                _detail('Gender', _text(pet['gender'])),
                _detail('Behaviour', _displayList(pet['behaviour'])),
                _detail('Special Care', _displayList(pet['specialCare'])),
                _detail('Notes', _text(pet['notes'])),
              ]),
              const SizedBox(height: 14),
              _section('Pickup Address', [
                _detail('Address Type',
                    _text(_map(data['pickupAddress'])['label'])),
                _detail(
                  'Full Address',
                  address.isEmpty ? 'Not provided' : address,
                ),
                _detail(
                  'Landmark',
                  _text(_map(data['pickupAddress'])['landmark']),
                ),
              ]),
              const SizedBox(height: 14),
              _section('Assigned Walker', [
                _detail('Walker ID', _text(data['walkerId'], fallback: 'Not assigned')),
                const Text(
                  'Walker name and contact details will appear after '
                  'the assignment process provides those fields.',
                  style: TextStyle(
                    color: bookingsMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ]),
              if (regular) ...[
                const SizedBox(height: 14),
                _section('Regular Walk Plan', [
                  _detail('Frequency', _text(data['frequency'])),
                  _detail('Walks Per Week',
                      _text(data['walksPerWeek'])),
                  _detail('Preferred Time',
                      _text(data['preferredTime'])),
                  const Text(
                    'Extra daily times and plan dates are shown only '
                    'when saved in the booking record.',
                    style: TextStyle(
                      color: bookingsMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 14),
              _CancellationSection(
                documentId: documentId,
                data: data,
              ),
              const SizedBox(height: 14),
              _section('Help & Support', const [
                Text(
                  'Booking mein koi problem hai? DOJO WALK Support se '
                  'contact karein.',
                  style: TextStyle(height: 1.5),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _CancellationSection extends StatelessWidget {
  const _CancellationSection({
    required this.documentId,
    required this.data,
  });

  final String documentId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final request = data['cancelRequest'];
    final requestMap = request is Map
        ? Map<String, dynamic>.from(request)
        : <String, dynamic>{};

    final requestStatus = request == null
        ? 'Not Requested'
        : _text(requestMap['status'], fallback: 'Pending');

    final status = _status(data);
    final terminal = status == 'completed' ||
        status == 'cancelled' ||
        status == 'canceled';

    return _section('Cancel Request', [
      _detail('Request Status', requestStatus),
      if (status == 'cancelled' || status == 'canceled')
        const Text('This booking is already cancelled.')
      else if (status == 'completed')
        const Text('Completed bookings cannot be cancelled here.')
      else if (requestStatus.toLowerCase() == 'pending')
        const Text(
          'Request sent. The booking will not be cancelled automatically.',
        )
      else if (requestStatus.toLowerCase() == 'approved')
        const Text(
          'Request approved. Check the booking status for final cancellation.',
        )
      else if (requestStatus.toLowerCase() == 'rejected')
        const Text('Your cancellation request was rejected.')
      else if (!terminal)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Request Cancellation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: () => _request(context),
          ),
        ),
    ]);
  }

  Future<void> _request(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Cancellation?'),
        content: const Text(
          'Your request will be saved for review. '
          'This will not automatically cancel your booking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final ref = FirebaseFirestore.instance
          .collection('bookings')
          .doc(documentId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('Booking not found.');
        }

        final current = snapshot.data() ?? <String, dynamic>{};

        if (current['customerId'] != user.uid) {
          throw Exception('You cannot change this booking.');
        }

        final status = _status(current);
        if ([
          'completed',
          'cancelled',
          'canceled',
        ].contains(status)) {
          throw Exception('This booking cannot be cancelled.');
        }

        final existing = current['cancelRequest'];
        if (existing is Map &&
            _text(existing['status']).toLowerCase() == 'pending') {
          throw Exception('A cancellation request is already pending.');
        }

        transaction.update(ref, {
          'cancelRequest': {
            'status': 'Pending',
            'requestedBy': user.uid,
            'requestedAt': FieldValue.serverTimestamp(),
          },
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancellation request submitted.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request failed: $e')),
        );
      }
    }
  }
}

Widget _section(String title, List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF0E9E2)),
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

Widget _statusBadge(String status) {
  final color = status == 'completed'
      ? Colors.green
      : (status == 'cancelled' || status == 'canceled')
          ? Colors.red
          : bookingsOrange;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      status.replaceAll('_', ' ').toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

Map<String, dynamic> _petDetails(Map<String, dynamic> data) {
  return _map(data['petDetails']);
}

String _status(Map<String, dynamic> data) {
  return _text(data['status'], fallback: 'pending').toLowerCase();
}

bool _isUpcoming(String status) {
  return [
    'pending',
    'confirmed',
    'assigned',
    'accepted',
    'in_progress',
    'in progress',
  ].contains(status);
}

String _plan(Map<String, dynamic> data) {
  final plan = _text(data['bookingPlan']).toLowerCase();
  final service = _text(data['serviceType']).toLowerCase();

  if (plan == 'regular' || service == 'regular_walk') {
    return 'Regular Walk';
  }
  return 'One-Time Walk';
}

String _duration(Map<String, dynamic> data) {
  final value = data['duration'];
  if (value == null || value.toString().trim().isEmpty) {
    return 'Not provided';
  }

  final text = value.toString().trim();
  if (RegExp(r'^\d+$').hasMatch(text)) {
    return '$text minutes';
  }
  return text.toLowerCase().contains('minute') ? text : '$text minutes';
}

String _text(dynamic value, {String fallback = 'Not provided'}) {
  if (value == null) return fallback;
  if (value is List) return value.map((e) => e.toString()).join(', ');

  final result = value.toString().trim();
  return result.isEmpty ? fallback : result;
}

String _displayList(dynamic value) {
  if (value is List) {
    final values = value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return values.isEmpty ? 'Not provided' : values.join(', ');
  }
  return _text(value);
}

String _age(dynamic value) {
  final age = _text(value);
  if (age == 'Not provided') return age;

  if (RegExp(r'^\d+$').hasMatch(age)) {
    return age == '1' ? '1 year' : '$age years';
  }
  return age;
}

String _address(dynamic value) {
  final address = _map(value);

  return [
    address['label'],
    address['address'],
    address['area'],
    address['landmark'],
    address['city'],
    address['pincode'],
  ]
      .where((v) => v != null && v.toString().trim().isNotEmpty)
      .map((v) => v.toString().trim())
      .toSet()
      .join(', ');
}

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime(2000);
  return DateTime(2000);
}

String _formatDate(DateTime date) {
  if (date.year <= 2000) return 'Not provided';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatTime(DateTime date) {
  if (date.year <= 2000) return 'Not provided';

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
}
