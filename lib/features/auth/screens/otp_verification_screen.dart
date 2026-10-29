
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../app/locale_controller.dart';

const Color dojoOrange = DojoWalkTheme.primary;
const Color dojoBackground = DojoWalkTheme.background;

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

  String _tr(String en, String hi, String bn) {
    switch (appLocale.value.languageCode) {
      case 'hi':
        return hi;
      case 'bn':
        return bn;
      default:
        return en;
    }
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code':
        return _tr('Invalid OTP. Please check and try again.', 'गलत OTP है। जाँचकर फिर कोशिश करें।', 'ভুল OTP। যাচাই করে আবার চেষ্টা করুন।');

      case 'session-expired':
      case 'invalid-verification-id':
        return _tr('OTP expired. Please request a new OTP.', 'OTP की अवधि समाप्त हो गई। नया OTP मँगाएँ।', 'OTP-এর মেয়াদ শেষ। নতুন OTP নিন।');

      case 'too-many-requests':
        return _tr('Too many attempts. Please try again later.', 'बहुत ज़्यादा कोशिशें हुईं। बाद में फिर कोशिश करें।', 'অনেকবার চেষ্টা হয়েছে। পরে আবার চেষ্টা করুন।');

      case 'quota-exceeded':
        return _tr('Firebase SMS quota exceeded. Please try later.', 'SMS सीमा पूरी हो गई है। बाद में कोशिश करें।', 'SMS সীমা শেষ। পরে আবার চেষ্টা করুন।');

      case 'network-request-failed':
        return _tr('Check your internet connection and try again.', 'इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।', 'ইন্টারনেট সংযোগ যাচাই করে আবার চেষ্টা করুন।');

      case 'operation-not-allowed':
        return _tr('Phone Authentication is not enabled in Firebase.', 'Firebase में Phone Authentication चालू नहीं है।', 'Firebase-এ Phone Authentication চালু নেই।');

      case 'app-not-authorized':
        return _tr('This app is not authorized in Firebase.', 'यह ऐप Firebase में अधिकृत नहीं है।', 'এই অ্যাপ Firebase-এ অনুমোদিত নয়।');

      default:
        return error.message ?? _tr('Something went wrong. Please try again.', 'कुछ गड़बड़ हुई। फिर कोशिश करें।', 'কিছু সমস্যা হয়েছে। আবার চেষ্টা করুন।');
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

        _message(_tr('Login was unsuccessful. Please try again.', 'लॉगिन नहीं हो पाया। फिर कोशिश करें।', 'লগইন হয়নি। আবার চেষ্টা করুন।'));
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

      _message(_tr('Login failed. Please try again.', 'लॉगिन विफल हुआ। फिर कोशिश करें।', 'লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'));
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading || _finished || _resending) return;

    final otp = _otpController.text.trim();
    final verificationId = _verificationId;

    if (verificationId == null || verificationId.isEmpty) {
      _message(_tr('Please request an OTP first.', 'पहले OTP मँगाएँ।', 'আগে OTP নিন।'));
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _message(_tr('Please enter the 6-digit OTP.', '6 अंकों का OTP डालें।', '৬ সংখ্যার OTP লিখুন।'));
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
          _message(_tr('A new OTP has been sent.', 'नया OTP भेज दिया गया है।', 'নতুন OTP পাঠানো হয়েছে।'));
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

      _message(_tr('Unable to resend OTP. Please try again.', 'OTP दोबारा नहीं भेज सके। फिर कोशिश करें।', 'OTP আবার পাঠানো যায়নি। আবার চেষ্টা করুন।'));
    }
  }

  void _changeMobileNumber() {
    if (_loading || _finished) return;

    _timer?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) => Scaffold(
      backgroundColor: dojoBackground,
      appBar: AppBar(
        backgroundColor: dojoBackground,
        elevation: 0,
        title: Text(
          _tr('Verify OTP', 'OTP सत्यापित करें', 'OTP যাচাই করুন'),
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

              Text(
                _tr('Verify Your Number', 'अपना नंबर सत्यापित करें', 'আপনার নম্বর যাচাই করুন'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _tr('We sent an OTP to this number:', 'इस नंबर पर OTP भेजा गया है:', 'এই নম্বরে OTP পাঠানো হয়েছে:'),
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

              Text(
                _tr('6-Digit OTP', '6 अंकों का OTP', '৬ সংখ্যার OTP'),
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
                  hintText: _tr('Enter OTP', 'OTP डालें', 'OTP লিখুন'),
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
                    disabledBackgroundColor:
                        dojoOrange.withValues(alpha: 0.55),
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
                          _tr('Verify OTP', 'OTP सत्यापित करें', 'OTP যাচাই করুন'),
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
                        ? _tr('Resend OTP in $_secondsRemaining sec', '$_secondsRemaining सेकंड में OTP दोबारा भेजें', '$_secondsRemaining সেকেন্ডে OTP আবার পাঠান')
                        : _tr('Resend OTP', 'OTP दोबारा भेजें', 'OTP আবার পাঠান'),
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
                  child: Text(
                    _tr('Change Mobile Number', 'मोबाइल नंबर बदलें', 'মোবাইল নম্বর পরিবর্তন করুন'),
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  _tr('Secure login with DOJO WALK', 'DOJO WALK के साथ सुरक्षित लॉगिन', 'DOJO WALK-এর সঙ্গে নিরাপদ লগইন'),
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
