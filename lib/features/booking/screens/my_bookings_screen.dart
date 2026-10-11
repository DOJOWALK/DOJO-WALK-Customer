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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bookingsBackground,
      appBar: AppBar(
        backgroundColor: bookingsBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: bookingsText,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: bookingsText,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: _buildEmptyState(),
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
        message = 'Your dog walking bookings will appear here.';
    }

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
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 54,
                color: bookingsOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Bookings Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 19,
                ),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: bookingsOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bookings will appear here after the booking system is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bookingsMuted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
