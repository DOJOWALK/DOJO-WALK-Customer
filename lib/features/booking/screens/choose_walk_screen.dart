
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/screens/phone_login_screen.dart';
import '../../profile/screens/name_setup_screen.dart';
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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  DateTime? _parseDateOfBirth(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    var age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age;
  }

  bool _isAdult(DateTime? dob) {
    if (dob == null || dob.isAfter(DateTime.now())) {
      return false;
    }

    return _calculateAge(dob) >= 18;
  }

  Future<bool> _hasCompleteAdultProfile(User user) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = snapshot.data() ?? <String, dynamic>{};

    final name = (data['name'] ?? '').toString().trim();
    final gender = (data['gender'] ?? '').toString();
    final dob = _parseDateOfBirth(data['dateOfBirth']);

    return snapshot.exists &&
        name.length >= 2 &&
        ['male', 'female', 'other'].contains(gender) &&
        _isAdult(dob);
  }

  Future<void> _openSchedule(WalkBookingType selected) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WalkScheduleScreen(walkType: selected),
      ),
    );
  }

  Future<void> _continue() async {
    if (_openingNextScreen) return;

    final selected = _selectedType;

    if (selected == null) {
      _showMessage('Please select a walk type first.');
      return;
    }

    setState(() => _openingNextScreen = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      // Guest: login first, then continue to the selected walk schedule.
      if (user == null) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => PhoneLoginScreen(
              bookingWalkType: selected.name,
            ),
          ),
        );

        if (!mounted || result != true) return;

        // PhoneLoginScreen only returns true after login and profile
        // validation have completed successfully.
        await _openSchedule(selected);
        return;
      }

      // Signed-in customer: validate profile before booking.
      final profileComplete = await _hasCompleteAdultProfile(user);

      if (!mounted) return;

      if (profileComplete) {
        await _openSchedule(selected);
        return;
      }

      // Incomplete or underage profile: open Profile Setup.
      // Its booking flow returns true to this screen after saving.
      final profileResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => NameSetupScreen(
            bookingWalkType: selected.name,
          ),
        ),
      );

      if (!mounted || profileResult != true) return;

      // Re-check the saved profile before allowing booking.
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser == null) {
        _showMessage('Please log in again before booking.');
        return;
      }

      final updatedProfileComplete =
          await _hasCompleteAdultProfile(updatedUser);

      if (!mounted) return;

      if (!updatedProfileComplete) {
        _showMessage(
          'Your profile must be complete and you must be at least 18 to book.',
        );
        return;
      }

      await _openSchedule(selected);
    } on FirebaseException catch (error) {
      _showMessage(
        'Unable to continue. Please check your connection and Firebase permissions. (${error.code})',
      );
    } catch (_) {
      _showMessage(
        'Unable to continue. Please try again.',
      );
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
