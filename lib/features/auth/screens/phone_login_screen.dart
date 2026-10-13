
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'otp_verification_screen.dart';
import '../../profile/screens/name_setup_screen.dart';
import '../../../app/app_navigator.dart';

const Color dojoOrange = Color(0xFFFF7900);
const Color dojoBackground = Color(0xFFFFFAF5);

class PhoneLoginScreen extends StatefulWidget {
  /// Null means normal login.
  /// Otherwise preserves the selected booking type.
  final String? bookingWalkType;

  const PhoneLoginScreen({
    super.key,
    this.bookingWalkType,
  });

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController =
      TextEditingController();

  bool _loading = false;
  bool _openingNextScreen = false;
  bool _otpScreenOpen = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _message(String message) {
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

  Future<void> _continueAfterLogin() async {
    if (!mounted || _openingNextScreen) return;

    _openingNextScreen = true;
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Login session नहीं मिली। दोबारा OTP verify करें।');
      }

      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = profile.data() ?? <String, dynamic>{};

      final name = data['name'];
      final gender = data['gender'];
      final dob = _parseDateOfBirth(data['dateOfBirth']);

      final hasName =
          name is String && name.trim().length >= 2;

      final hasGender = gender is String &&
          ['male', 'female', 'other'].contains(gender);

      final hasValidDob =
          dob != null && !dob.isAfter(DateTime.now());

      final isAdult =
          hasValidDob && _calculateAge(dob) >= 18;

      final profileComplete = profile.exists &&
          hasName &&
          hasGender &&
          hasValidDob &&
          isAdult;

      if (!profileComplete) {
        if (widget.bookingWalkType != null) {
          // Keep PhoneLogin underneath Profile Setup.
          // Profile Setup returns true after saving successfully.
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => NameSetupScreen(
                bookingWalkType: widget.bookingWalkType,
              ),
            ),
          );

          if (!mounted) return;

          if (result == true) {
            Navigator.of(context).pop(true);
          }

          return;
        }

        // Normal login: Profile Setup leads to AppNavigator.
        await Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => const NameSetupScreen(),
          ),
        );
        return;
      }

      if (widget.bookingWalkType != null) {
        // Let ChooseWalkScreen continue to Schedule.
        Navigator.of(context).pop(true);
        return;
      }

      // Normal login goes to the main application.
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => const AppNavigator(),
        ),
      );
    } on FirebaseException catch (error) {
      if (mounted) {
        _message(
          'अकाउंट की जानकारी नहीं मिल पाई। '
          'इंटरनेट या Firebase permissions जाँचें। '
          '(${error.code})',
        );
      }
    } catch (error) {
      if (mounted) {
        _message('आगे नहीं बढ़ पाए: $error');
      }
    } finally {
      _openingNextScreen = false;

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_loading || _openingNextScreen || _otpScreenOpen) {
      return;
    }

    final phone = _phoneController.text.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _message('सही 10 अंकों का भारतीय मोबाइल नंबर डालें।');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          if (!mounted || _openingNextScreen) return;

          try {
            final result = await FirebaseAuth.instance
                .signInWithCredential(credential);

            if (!mounted || _openingNextScreen) return;

            if (result.user != null) {
              await _continueAfterLogin();
            } else {
              setState(() => _loading = false);
              _message('Login पूरा नहीं हुआ।');
            }
          } on FirebaseAuthException catch (error) {
            if (!mounted) return;

            setState(() => _loading = false);
            _message(
              error.message ??
                  'Automatic verification नहीं हुआ।',
            );
          } catch (_) {
            if (!mounted) return;

            setState(() => _loading = false);
            _message('Login में समस्या हुई। OTP से कोशिश करें।');
          }
        },

        verificationFailed: (FirebaseAuthException error) {
          if (!mounted) return;

          setState(() => _loading = false);
          _message(error.message ?? 'OTP नहीं भेजा जा सका।');
        },

        codeSent: (String verificationId, int? resendToken) async {
          if (!mounted || _openingNextScreen || _otpScreenOpen) {
            return;
          }

          setState(() {
            _loading = false;
            _otpScreenOpen = true;
          });

          bool? verified;

          try {
            verified = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => OtpVerificationScreen(
                  phoneNumber: '+91$phone',
                  verificationId: verificationId,
                  resendToken: resendToken,
                ),
              ),
            );
          } finally {
            _otpScreenOpen = false;
          }

          if (!mounted) return;

          if (verified == true) {
            await _continueAfterLogin();
          }
        },

        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message(error.message ?? 'OTP भेजने में समस्या हुई।');
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('समस्या हुई। इंटरनेट जाँचकर दोबारा कोशिश करें।');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dojoBackground,
      appBar: AppBar(
        backgroundColor: dojoBackground,
        elevation: 0,
        title: const Text(
          'Phone Login',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),
              const Icon(
                Icons.phone_android,
                size: 54,
                color: dojoOrange,
              ),
              const SizedBox(height: 22),
              const Text(
                'Welcome to DOJO WALK',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ऐप में आगे बढ़ने के लिए अपना मोबाइल नंबर डालें।',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Mobile Number',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                enabled: !_loading,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  prefixText: '+91  ',
                  hintText: '10 अंकों का मोबाइल नंबर',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: dojoOrange,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dojoOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Secure login with DOJO WALK',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
