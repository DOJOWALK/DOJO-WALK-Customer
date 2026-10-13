
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_navigator.dart';
import '../../auth/screens/phone_login_screen.dart';
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

  Future<void> _checkLoginAndNavigate() async {
    if (!mounted || _navigated || _checking) return;

    _checking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _openNextScreen(const PhoneLoginScreen());
        return;
      }

      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted || _navigated) return;

      final data = profile.data();

      final name = data?['name'];
      final gender = data?['gender'];
      final dob = data?['dateOfBirth'];

      final hasName =
          name is String && name.trim().length >= 2;

      final hasGender = gender is String &&
          ['male', 'female', 'other'].contains(gender);

      final hasDob = dob is Timestamp ||
          (dob is String && DateTime.tryParse(dob) != null);

      if (!profile.exists ||
          !hasName ||
          !hasGender ||
          !hasDob) {
        _openNextScreen(const NameSetupScreen());
        return;
      }

      _openNextScreen(const AppNavigator());
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'अकाउंट चेक नहीं हो पाया।\nइंटरनेट जाँचें और दोबारा कोशिश करें।';
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
            // आपकी पूरी Splash Screen image
            Image.asset(
              'assets/images/dojo_splash.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: splashOrange,
                  child: Center(
                    child: Text(
                      'DOJO WALK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

            // सफेद loading spinner — image के ऊपर
            if (_error == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).size.height * 0.105,
                child: const Center(
                  child: SizedBox(
                    width: 27,
                    height: 27,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),

            // Error होने पर retry विकल्प
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
