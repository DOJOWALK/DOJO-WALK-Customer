import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_navigator.dart';
import '../../profile/screens/name_setup_screen.dart';

const Color splashOrange = Color(0xFFFF7900);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  bool _navigated = false;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _timer = Timer(
      const Duration(seconds: 2),
      _checkLoginAndNavigate,
    );
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

  DateTime? _parseDateOfBirth(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  Future<void> _checkLoginAndNavigate() async {
    if (!mounted || _navigated || _checking) return;

    _checking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Guest users can browse without logging in.
      if (user == null) {
        _openNextScreen(const AppNavigator());
        return;
      }

      // Verify authenticated customer's profile.
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted || _navigated) return;

      final data = profile.data();

      final name = data?['name'];
      final gender = data?['gender'];
      final dobValue = data?['dateOfBirth'];

      final hasName =
          name is String && name.trim().length >= 2;

      final hasGender = gender is String &&
          ['male', 'female', 'other'].contains(gender);

      final dob = _parseDateOfBirth(dobValue);

      final hasValidDob =
          dob != null && !dob.isAfter(DateTime.now());

      final isAdult =
          hasValidDob && _calculateAge(dob) >= 18;

      // Incomplete or invalid profiles must be completed.
      if (!profile.exists ||
          !hasName ||
          !hasGender ||
          !hasValidDob ||
          !isAdult) {
        _openNextScreen(const NameSetupScreen());
        return;
      }

      _openNextScreen(const AppNavigator());
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'Unable to verify your account.\n'
            'Please check your internet connection and try again.';
      });
    } finally {
      _checking = false;
    }
  }

  void _openNextScreen(Widget screen) {
    if (!mounted || _navigated) return;

    _navigated = true;
    _timer?.cancel();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashOrange,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen DOJO WALK wallpaper.
            Image.asset(
              'assets/images/DOJO WALK SPLASH.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: splashOrange,
                );
              },
            ),

            // Loading and branding stay together near the bottom.
            if (_error == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).size.height * 0.105,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 27,
                        height: 27,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Powered by DOJO WALK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Retry message if account verification fails.
            if (_error != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _checking
                            ? null
                            : () {
                                setState(() {
                                  _error = null;
                                });
                                _checkLoginAndNavigate();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: splashOrange,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
