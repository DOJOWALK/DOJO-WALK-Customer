
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

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

  String _friendlyError(FirebaseAuthException error) {
    final l10n = AppLocalizations.of(context);
    switch (error.code) {
      case 'invalid-verification-code':
        return l10n.otpInvalidCode;
      case 'session-expired':
      case 'invalid-verification-id':
        return l10n.otpExpired;
      case 'too-many-requests':
        return l10n.otpTooManyAttempts;
      case 'quota-exceeded':
        return l10n.otpSmsQuotaExceeded;
      case 'network-request-failed':
        return l10n.otpNetworkError;
      case 'operation-not-allowed':
        return l10n.otpPhoneAuthDisabled;
      case 'app-not-authorized':
        return l10n.otpAppUnauthorized;
      default:
        return l10n.otpGenericError;
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

        _message(AppLocalizations.of(context).otpLoginUnsuccessful);
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

      _message(AppLocalizations.of(context).otpLoginFailed);
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading || _finished || _resending) return;

    final otp = _otpController.text.trim();
    final verificationId = _verificationId;

    if (verificationId == null || verificationId.isEmpty) {
      _message(AppLocalizations.of(context).otpRequestFirst);
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _message(AppLocalizations.of(context).otpEnterSixDigits);
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
          _message(AppLocalizations.of(context).otpNewSent);
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

      _message(AppLocalizations.of(context).otpResendFailed);
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
          AppLocalizations.of(context).otpVerifyTitle,
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
                AppLocalizations.of(context).otpVerifyNumberTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                AppLocalizations.of(context).otpSentToNumber,
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
                AppLocalizations.of(context).otpSixDigitLabel,
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
                  hintText: AppLocalizations.of(context).otpEnterHint,
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
                          AppLocalizations.of(context).otpVerifyTitle,
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
                        ? '${AppLocalizations.of(context).otpResendIn} $_secondsRemaining ${AppLocalizations.of(context).otpSeconds}'
                        : AppLocalizations.of(context).otpResend,
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
                    AppLocalizations.of(context).otpChangeMobile,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  AppLocalizations.of(context).secureLogin,
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
      ),
    );
  }
}
