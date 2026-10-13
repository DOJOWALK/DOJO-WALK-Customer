
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'otp_verification_screen.dart';

const Color dojoOrange = Color(0xFFFF7900);
const Color dojoBackground = Color(0xFFFFFAF5);

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _sendOtp() async {
    if (_loading) return;

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

        verificationCompleted: (credential) async {
          try {
            final result = await FirebaseAuth.instance
                .signInWithCredential(credential);

            if (!mounted) return;

            if (result.user != null) {
              Navigator.of(context).pop(true);
            }
          } on FirebaseAuthException catch (e) {
            _message(e.message ?? 'Login पूरा नहीं हुआ।');
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },

        verificationFailed: (error) {
          if (!mounted) return;
          setState(() => _loading = false);

          _message(
            error.message ?? 'OTP नहीं भेजा जा सका।',
          );
        },

        codeSent: (verificationId, resendToken) async {
          if (!mounted) return;

          setState(() => _loading = false);

          final verified = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                phoneNumber: '+91$phone',
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );

          if (!mounted) return;

          if (verified == true) {
            Navigator.of(context).pop(true);
          }
        },

        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(e.message ?? 'OTP भेजने में समस्या हुई।');
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('इंटरनेट और Firebase सेटिंग जाँचें।');
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
                'बुकिंग जारी रखने के लिए अपना मोबाइल नंबर डालें।',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
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
                          height: 22,
                          width: 22,
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
              const SizedBox(height: 18),
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
