
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color dojoOrange = Color(0xFFFF7900);
const Color dojoBackground = Color(0xFFFFFAF5);

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final TextEditingController _otpController =
      TextEditingController();

  String? _verificationId;
  int? _resendToken;

  bool _loading = false;
  bool _resending = false;
  bool _finished = false;

  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted || _finished) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';

      case 'session-expired':
      case 'invalid-verification-id':
        return 'OTP expired. Please request a new OTP.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'quota-exceeded':
        return 'Firebase SMS quota exceeded. Please try later.';

      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      case 'operation-not-allowed':
        return 'Phone Authentication is not enabled in Firebase.';

      case 'app-not-authorized':
        return 'This app is not authorized in Firebase.';

      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _secondsRemaining = 60;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted || _finished) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining <= 1) {
          timer.cancel();
          setState(() {
            _secondsRemaining = 0;
          });
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  void _finishLogin() {
    if (!mounted || _finished) return;

    _finished = true;
    _timer?.cancel();

    Navigator.of(context).pop(true);
  }

  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    if (!mounted || _finished) return;

    try {
      final result = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (!mounted || _finished) return;

      if (result.user != null) {
        _finishLogin();
      } else {
        setState(() {
          _loading = false;
          _resending = false;
        });

        _message('Login was unsuccessful. Please try again.');
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted || _finished) return;

      setState(() {
        _loading = false;
        _resending = false;
      });

      _message(_friendlyError(error));
    } catch (_) {
      if (!mounted || _finished) return;

      setState(() {
        _loading = false;
        _resending = false;
      });

      _message('Login failed. Please try again.');
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading || _finished || _resending) return;

    final otp = _otpController.text.trim();
    final verificationId = _verificationId;

    if (verificationId == null || verificationId.isEmpty) {
      _message('Please request an OTP first.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _message('Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _loading = true;
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    await _signInWithCredential(credential);
  }

  Future<void> _resendOtp() async {
    if (_loading ||
        _secondsRemaining > 0 ||
        _finished ||
        _resending) {
      return;
    }

    setState(() {
      _loading = true;
      _resending = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,

        verificationCompleted: (PhoneAuthCredential credential) {
          if (!mounted || _finished) return;

          _signInWithCredential(credential);
        },

        verificationFailed: (FirebaseAuthException error) {
          if (!mounted || _finished) return;

          setState(() {
            _loading = false;
            _resending = false;
          });

          _message(_friendlyError(error));
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted || _finished) return;

          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _loading = false;
            _resending = false;
            _otpController.clear();
          });

          _startTimer();
          _message('A new OTP has been sent.');
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted || _finished) return;

          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted || _finished) return;

      setState(() {
        _loading = false;
        _resending = false;
      });

      _message(_friendlyError(error));
    } catch (_) {
      if (!mounted || _finished) return;

      setState(() {
        _loading = false;
        _resending = false;
      });

      _message('Unable to resend OTP. Please try again.');
    }
  }

  void _changeMobileNumber() {
    if (_loading || _finished) return;

    _timer?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dojoBackground,
      appBar: AppBar(
        backgroundColor: dojoBackground,
        elevation: 0,
        title: const Text(
          'Verify OTP',
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

              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD9B8), Color(0xFFFFF7EF)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: dojoOrange.withValues(alpha: 0.20),
                        blurRadius: 24,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: dojoOrange,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Verify Your Number',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'We sent an OTP to this number:',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                '6-Digit OTP',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _otpController,
                enabled: !_loading,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 6,
                onSubmitted: (_) {
                  if (!_loading) {
                    _verifyOtp();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Enter OTP',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: dojoOrange.withValues(alpha: 0.16),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: dojoOrange,
                      width: 1.7,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dojoOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        dojoOrange.withValues(alpha: 0.55),
                    elevation: 5,
                    shadowColor: dojoOrange.withValues(alpha: 0.32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: TextButton(
                  onPressed: _loading || _secondsRemaining > 0
                      ? null
                      : _resendOtp,
                  child: Text(
                    _secondsRemaining > 0
                        ? 'Resend OTP in $_secondsRemaining sec'
                        : 'Resend OTP',
                    style: const TextStyle(
                      color: dojoOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              Center(
                child: TextButton(
                  onPressed: _loading ? null : _changeMobileNumber,
                  child: const Text(
                    'Change Mobile Number',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

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
