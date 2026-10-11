import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/screens/phone_login_screen.dart';
import 'dog_details_screen.dart';

const Color bookingOrange = Color(0xFFFF7900);
const Color bookingBackground = Color(0xFFFFFAF5);
const Color bookingText = Color(0xFF202020);

enum WalkBookingType {
  oneTime,
  regular,
}

class BookingStartScreen extends StatefulWidget {
  const BookingStartScreen({
    super.key,
    this.initialType,
  });

  final WalkBookingType? initialType;

  @override
  State<BookingStartScreen> createState() =>
      _BookingStartScreenState();
}

class _BookingStartScreenState extends State<BookingStartScreen> {
  WalkBookingType? _selectedType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Future<void> _continueBooking() async {
    final selectedType = _selectedType;

    if (selectedType == null) {
      _showMessage('Please select a walk type first.');
      return;
    }

    if (_loading) return;

    setState(() => _loading = true);

    try {
      // Refresh the current Firebase login session.
      await FirebaseAuth.instance.currentUser?.reload();

      User? user = FirebaseAuth.instance.currentUser;

      // If the customer is not logged in with a verified phone,
      // open the phone OTP screen.
      if (user == null || user.phoneNumber == null) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => const PhoneLoginScreen(),
          ),
        );

        if (!mounted) return;

        // If the customer cancels or OTP fails, stop here.
        if (result != true) {
          setState(() => _loading = false);
          return;
        }

        // Confirm that Firebase now has an authenticated phone user.
        user = FirebaseAuth.instance.currentUser;

        if (user == null || user.phoneNumber == null) {
          setState(() => _loading = false);
          _showMessage('Mobile verification complete nahi hui.');
          return;
        }
      }

      if (!mounted) return;

      setState(() => _loading = false);

      // Keep the selected walk type and continue to Dog Details.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DogDetailsScreen(
            walkType: selectedType,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(e.message ?? 'Login check failed. Please try again.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Something went wrong. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bookingBackground,
      appBar: AppBar(
        backgroundColor: bookingBackground,
        elevation: 0,
        title: const Text(
          'Book a Walk',
          style: TextStyle(
            color: bookingText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),

            const Text(
              'Choose your walk',
              style: TextStyle(
                fontSize: 29,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: bookingText,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'Select the walking service that suits your dog.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 28),

            _walkOption(
              type: WalkBookingType.oneTime,
              title: 'One-Time Walk',
              subtitle: 'Book a single dog walk.',
              icon: Icons.directions_walk_rounded,
              badge: 'ONE TIME',
            ),

            const SizedBox(height: 16),

            _walkOption(
              type: WalkBookingType.regular,
              title: 'Regular Walks',
              subtitle: 'Plan recurring walks for your dog.',
              icon: Icons.calendar_month_rounded,
              badge: 'REPEAT',
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
                    Icons.verified_user_outlined,
                    color: bookingOrange,
                    size: 23,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your mobile login will be checked when you '
                      'continue. If you are not logged in, you will '
                      'be asked to verify your number using OTP.',
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

            const SizedBox(height: 26),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _continueBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bookingOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      bookingOrange.withValues(alpha: 0.55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 14),

            const Center(
              child: Text(
                'Secure booking with DOJO WALK',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walkOption({
    required WalkBookingType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
  }) {
    final selected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() => _selectedType = type);
      },
      borderRadius: BorderRadius.circular(19),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bookingOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: bookingOrange,
                size: 30,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bookingOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.6,
                        color: bookingOrange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: bookingText,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
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
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
