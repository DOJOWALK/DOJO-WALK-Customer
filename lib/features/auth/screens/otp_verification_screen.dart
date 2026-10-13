
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'phone_login_screen.dart';

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
  final _otpController = TextEditingController();

  String? _verificationId;
  int? _resendToken;

  bool _loading = false;
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

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code':
        return 'OTP गलत है। दोबारा जाँचें।';
      case 'session-expired':
        return 'OTP की समय सीमा समाप्त हो गई। नया OTP मँगाएँ।';
      case 'too-many-requests':
        return 'बहुत बार कोशिश हुई है। बाद में फिर कोशिश करें।';
      case 'quota-exceeded':
        return 'Firebase SMS की सीमा पूरी हो गई है।';
      case 'network-request-failed':
        return 'इंटरनेट कनेक्शन जाँचें।';
      default:
        return error.message ?? 'समस्या हुई। दोबारा कोशिश करें।';
    }
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() => _secondsRemaining = 60);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining <= 1) {
          timer.cancel();
          setState(() => _secondsRemaining = 0);
        } else {
          setState(() => _secondsRemaining--);
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

  Future<void> _verifyOtp() async {
    if (_loading || _finished) return;

    final otp = _otpController.text.trim();
    final verificationId = _verificationId;

    if (verificationId == null) {
      _message('पहले OTP मँगाएँ।');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _message('6 अंकों का OTP डालें।');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final result = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (!mounted) return;

      if (result.user != null) {
        _finishLogin();
      } else {
        setState(() => _loading = false);
        _message('Login पूरा नहीं हुआ।');
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message(_friendlyError(error));
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('OTP Verify नहीं हुआ। दोबारा कोशिश करें।');
    }
  }

  Future<void> _resendOtp() async {
    if (_loading || _secondsRemaining > 0 || _finished) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,

        verificationCompleted: (credential) async {
          try {
            final result = await FirebaseAuth.instance
                .signInWithCredential(credential);

            if (!mounted) return;

            if (result.user != null) {
              _finishLogin();
            }
          } on FirebaseAuthException catch (error) {
            if (!mounted) return;
            setState(() => _loading = false);
            _message(_friendlyError(error));
          }
        },

        verificationFailed: (error) {
          if (!mounted) return;

          setState(() => _loading = false);
          _message(_friendlyError(error));
        },

        codeSent: (verificationId, resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _loading = false;
            _otpController.clear();
          });

          _startTimer();
          _message('नया OTP भेज दिया गया है।');
        },

        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message(_friendlyError(error));
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('OTP दोबारा नहीं भेजा जा सका।');
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
              const Icon(
                Icons.mark_email_read_outlined,
                size: 54,
                color: dojoOrange,
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
                'हमने इस नंबर पर OTP भेजा है:',
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
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                enabled: !_loading,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onSubmitted: (_) {
                  if (!_loading) _verifyOtp();
                },
                decoration: InputDecoration(
                  hintText: 'Enter OTP',
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dojoOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Change Mobile Number',
                    style: TextStyle(color: Colors.black54),
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
