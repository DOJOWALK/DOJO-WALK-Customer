
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

      // 1. ग्राहक लॉगिन नहीं है।
      if (user == null) {
        _openNextScreen(const PhoneLoginScreen());
        return;
      }

      // 2. लॉगिन है, अब ग्राहक की प्रोफ़ाइल चेक करें।
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
          (dob is String &&
              DateTime.tryParse(dob) != null);

      // 3. अधूरी प्रोफ़ाइल हो तो Name Setup खोलें।
      if (!profile.exists ||
          !hasName ||
          !hasGender ||
          !hasDob) {
        _openNextScreen(const NameSetupScreen());
        return;
      }

      // 4. प्रोफ़ाइल पूरी है तो मुख्य ऐप खोलें।
      _openNextScreen(const AppNavigator());
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'अभी आपका अकाउंट चेक नहीं हो पाया।\nकृपया इंटरनेट कनेक्शन जाँचें और दोबारा कोशिश करें।';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: splashOrange,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'DOJO WALK',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0xFF202020),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Happier walks. Healthier dogs.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 36),

                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      backgroundColor: splashOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ] else
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: splashOrange,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
