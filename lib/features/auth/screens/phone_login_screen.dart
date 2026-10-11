
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() =>
      _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  bool _otpSent = false;
  bool _loading = false;
  bool _loginCompleted = false;

  int _secondsRemaining = 0;
  Timer? _resendTimer;

  static const Color orange = Color(0xFFFF7900);
  static const Color background = Color(0xFFFFFAF5);

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'मोबाइल नंबर सही नहीं है।';
      case 'invalid-verification-code':
        return 'OTP गलत है। सही OTP डालें।';
      case 'session-expired':
        return 'OTP की समय सीमा समाप्त हो गई। नया OTP मँगाएँ।';
      case 'too-many-requests':
        return 'बहुत बार कोशिश हुई है। कुछ समय बाद फिर कोशिश करें।';
      case 'quota-exceeded':
        return 'Firebase SMS की सीमा पूरी हो गई है।';
      case 'operation-not-allowed':
        return 'Firebase में Phone Authentication चालू करें।';
      case 'app-not-authorized':
        return 'Android ऐप की Firebase पहचान जाँचें।';
      case 'captcha-check-failed':
        return 'ऐप का सुरक्षा सत्यापन असफल हुआ।';
      case 'network-request-failed':
        return 'इंटरनेट कनेक्शन जाँचें।';
      case 'missing-phone-number':
        return 'मोबाइल नंबर डालें।';
      default:
        return error.message ??
            'समस्या हुई। कृपया दोबारा कोशिश करें।';
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() => _secondsRemaining = 60);

    _resendTimer = Timer.periodic(
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

  Future<void> _sendOtp({bool resend = false}) async {
    if (_loading || _loginCompleted) return;

    final phone = _phoneController.text.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showMessage('सही 10 अंकों का भारतीय मोबाइल नंबर डालें।');
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            final result =
                await _auth.signInWithCredential(credential);

            if (!mounted) return;

            if (result.user != null) {
              _finishLogin();
            } else {
              setState(() => _loading = false);
              _showMessage('लॉगिन पूरा नहीं हो पाया।');
            }
          } on FirebaseAuthException catch (error) {
            if (!mounted) return;

            setState(() => _loading = false);
            _showMessage(_friendlyError(error));
          } catch (_) {
            if (!mounted) return;

            setState(() => _loading = false);
            _showMessage('लॉगिन पूरा नहीं हो पाया।');
          }
        },

        verificationFailed: (FirebaseAuthException error) {
          if (!mounted) return;

          setState(() => _loading = false);
          _showMessage(_friendlyError(error));
        },

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _otpSent = true;
            _loading = false;
          });

          _startResendTimer();
          _showMessage(
            'OTP भेज दिया गया है। SMS में आया OTP डालें।',
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(_friendlyError(error));
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(
        'OTP भेजा नहीं जा सका। इंटरनेट और Firebase सेटिंग जाँचें।',
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading || _loginCompleted) return;

    final otp = _otpController.text.trim();
    final verificationId = _verificationId;

    if (verificationId == null) {
      _showMessage('पहले OTP मँगाएँ।');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('6 अंकों का OTP डालें।');
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final result = await _auth.signInWithCredential(credential);

      if (!mounted) return;

      if (result.user != null) {
        _finishLogin();
      } else {
        setState(() => _loading = false);
        _showMessage('लॉगिन पूरा नहीं हुआ।');
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(_friendlyError(error));
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('OTP Verify नहीं हुआ। दोबारा कोशिश करें।');
    }
  }

  void _finishLogin() {
    if (!mounted || _loginCompleted) return;

    _loginCompleted = true;
    _resendTimer?.cancel();

    // BookingStartScreen receives true after successful login.
    Navigator.of(context).pop(true);
  }

  void _changeNumber() {
    _resendTimer?.cancel();

    setState(() {
      _otpSent = false;
      _verificationId = null;
      _resendToken = null;
      _secondsRemaining = 0;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Phone Login',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              const Text(
                'Welcome to DOJO WALK',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _otpSent
                    ? 'SMS में मिले 6 अंकों के OTP से अपना मोबाइल नंबर Verify करें।'
                    : 'बुकिंग जारी रखने के लिए अपना मोबाइल नंबर Verify करें।',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
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
                enabled: !_otpSent && !_loading,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  prefixText: '+91 ',
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
                      color: orange,
                      width: 2,
                    ),
                  ),
                ),
              ),

              if (_otpSent) ...[
                const SizedBox(height: 24),

                const Text(
                  'Enter OTP',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _otpController,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onSubmitted: (_) {
                    if (!_loading) _verifyOtp();
                  },
                  decoration: InputDecoration(
                    hintText: '6 अंकों का OTP',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: orange,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: _loading || _secondsRemaining > 0
                        ? null
                        : () => _sendOtp(resend: true),
                    child: Text(
                      _secondsRemaining > 0
                          ? 'Resend OTP in $_secondsRemaining sec'
                          : 'Resend OTP',
                      style: TextStyle(
                        color: _secondsRemaining > 0
                            ? Colors.black45
                            : orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _changeNumber,
                    child: const Text(
                      'Change Mobile Number',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : _otpSent
                          ? _verifyOtp
                          : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.orange.shade200,
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
                      : Text(
                          _otpSent ? 'Verify OTP' : 'Send OTP',
                          style: const TextStyle(
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
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
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
