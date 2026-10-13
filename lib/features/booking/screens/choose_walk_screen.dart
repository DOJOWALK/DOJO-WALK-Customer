
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/screens/phone_login_screen.dart';
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
  bool _openingNextScreen = false;

  Future<void> _continue() async {
    if (_openingNextScreen) return;

    final selected = _selectedType;

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a walk type first.'),
        ),
      );
      return;
    }

    setState(() => _openingNextScreen = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user == null) {
        // Open login and wait for successful booking-flow completion.
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => PhoneLoginScreen(
              bookingWalkType: selected.name,
            ),
          ),
        );

        if (!mounted) return;

        // Login/Profile must explicitly return true.
        // Otherwise do not open Schedule.
        if (result != true) return;

        // Login screen has confirmed the customer can continue.
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WalkScheduleScreen(
              walkType: selected,
            ),
          ),
        );

        return;
      }

      // Signed-in users must have a complete adult profile.
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = profile.data() ?? <String, dynamic>{};
      final name = (data['name'] ?? '').toString().trim();
      final gender = (data['gender'] ?? '').toString();

      DateTime? dob;
      final rawDob = data['dateOfBirth'];

      if (rawDob is Timestamp) {
        dob = rawDob.toDate();
      } else if (rawDob is String) {
        dob = DateTime.tryParse(rawDob);
      }

      final today = DateTime.now();
      var age = 0;

      if (dob != null) {
        age = today.year - dob.year;
        if (today.month < dob.month ||
            (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
      }

      final profileComplete = name.isNotEmpty &&
          ['male', 'female', 'other'].contains(gender) &&
          dob != null &&
          !dob.isAfter(today) &&
          age >= 18;

      if (!profileComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete your profile before booking.',
            ),
          ),
        );

        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WalkScheduleScreen(
            walkType: selected,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to continue. Please check your internet connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingNextScreen = false);
      }
    }
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
              subtitle:
                  'Request a one-time walk as soon as possible.',
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
                border: Border.all(
                  color: const Color(0xFFEEEEEE),
                ),
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
                onPressed: _openingNextScreen ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bookingOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      bookingOrange.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _openingNextScreen
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
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
      onTap: _openingNextScreen
          ? null
          : () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? bookingOrange
                : const Color(0xFFE7E7E7),
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
              child: Icon(
                icon,
                color: bookingOrange,
                size: 28,
              ),
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
