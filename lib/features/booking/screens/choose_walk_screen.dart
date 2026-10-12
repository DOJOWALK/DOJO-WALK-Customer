
import 'package:flutter/material.dart';

import 'walk_schedule_screen.dart';

const Color bookingOrange = Color(0xFFFF7900);
const Color bookingBackground = Color(0xFFFFFAF5);
const Color bookingText = Color(0xFF202020);

enum WalkBookingType {
  oneTime,
  regular,
  chooseDates,
}

class ChooseWalkScreen extends StatefulWidget {
  const ChooseWalkScreen({super.key});

  @override
  State<ChooseWalkScreen> createState() => _ChooseWalkScreenState();
}

class _ChooseWalkScreenState extends State<ChooseWalkScreen> {
  WalkBookingType? _selectedType;

  void _continue() {
    final selected = _selectedType;

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a walk type first.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalkScheduleScreen(
          walkType: selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bookingBackground,
      appBar: AppBar(
        backgroundColor: bookingBackground,
        foregroundColor: bookingText,
        elevation: 0,
        title: const Text(
          'Choose Your Walk',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            const Text(
              'How would you like to book?',
              style: TextStyle(
                fontSize: 27,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: bookingText,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Choose the walking plan that suits your dog.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 26),

            _option(
              type: WalkBookingType.oneTime,
              title: 'Walk Now',
              subtitle: 'Request a one-time walk as soon as possible.',
              badge: 'ONE-TIME',
              icon: Icons.directions_walk_rounded,
            ),
            const SizedBox(height: 14),

            _option(
              type: WalkBookingType.regular,
              title: 'Daily Walk',
              subtitle:
                  'Set recurring daily walks at your preferred times.',
              badge: 'RECURRING',
              icon: Icons.wb_sunny_outlined,
            ),
            const SizedBox(height: 14),

            _option(
              type: WalkBookingType.chooseDates,
              title: 'Choose Dates',
              subtitle:
                  'Select the dates when you want your dog walked.',
              badge: 'FLEXIBLE',
              icon: Icons.calendar_month_rounded,
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: bookingOrange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Walk requests depend on service availability. '
                      'A request does not guarantee that a walker '
                      'is immediately available.',
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

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bookingOrange,
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
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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

  Widget _option({
    required WalkBookingType type,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
  }) {
    final selected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? bookingOrange : const Color(0xFFE7E7E7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bookingOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: bookingOrange, size: 28),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge,
                    style: const TextStyle(
                      color: bookingOrange,
                      fontSize: 9,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      color: bookingText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? bookingOrange : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
