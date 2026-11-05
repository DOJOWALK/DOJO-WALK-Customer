
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'otp_verification_screen.dart';
import '../../profile/screens/name_setup_screen.dart';
import '../../../app/app_navigator.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

const Color dojoOrange = DojoWalkTheme.primary;
const Color dojoBackground = DojoWalkTheme.background;

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
        throw Exception(AppLocalizations.of(context).loginSessionMissing);
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
    } on FirebaseException catch (_) {
      if (mounted) {
        _message(
          AppLocalizations.of(context).authAccountLoadFailed,
        );
      }
    } catch (_) {
      if (mounted) {
        _message(AppLocalizations.of(context).authContinueFailed);
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
      _message(AppLocalizations.of(context).invalidIndianMobile);
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
              _message(AppLocalizations.of(context).loginIncomplete);
            }
          } on FirebaseAuthException catch (_) {
            if (!mounted) return;

            setState(() => _loading = false);
            _message(
              AppLocalizations.of(context).automaticVerificationFailed,
            );
          } catch (_) {
            if (!mounted) return;

            setState(() => _loading = false);
            _message(AppLocalizations.of(context).automaticLoginFailed);
          }
        },

        verificationFailed: (FirebaseAuthException error) {
          if (!mounted) return;

          setState(() => _loading = false);
          _message(AppLocalizations.of(context).otpSendFailed);
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
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message(AppLocalizations.of(context).otpSendFallback);
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message(AppLocalizations.of(context).loginProblem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: dojoBackground,
      appBar: AppBar(
        backgroundColor: dojoBackground,
        elevation: 0,
        title: Text(
          l10n.phoneLoginTitle,
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
              Text(
                l10n.welcomeToDojoWalk,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.phoneLoginInstruction,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.mobileNumber,
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
                  hintText: l10n.mobileNumberHint,
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
                      : Text(
                          l10n.sendOtp,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  l10n.secureLogin,
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
