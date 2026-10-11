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

  final _auth = FirebaseAuth.instance;

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;

  static const Color orange = Color(0xFFFF7900);

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showMessage('सही 10 अंकों का मोबाइल नंबर डालें।');
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final result =
                await _auth.signInWithCredential(credential);

            if (!mounted) return;

            if (result.user != null) {
              Navigator.of(context).pop(true);
            }
          } catch (_) {
            if (mounted) {
              _showMessage('लॉगिन पूरा नहीं हो पाया।');
            }
          }
        },

        verificationFailed: (FirebaseAuthException error) {
          if (!mounted) return;

          setState(() => _loading = false);

          _showMessage(
            error.message ?? 'OTP भेजने में समस्या हुई।',
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });

          _showMessage('OTP भेज दिया गया है।');
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage('कुछ गलत हुआ। दोबारा कोशिश करें।');
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (_verificationId == null) {
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
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final result = await _auth.signInWithCredential(credential);

      if (!mounted) return;

      if (result.user != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _loading = false);
        _showMessage('लॉगिन पूरा नहीं हुआ।');
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);

      _showMessage(
        error.code == 'invalid-verification-code'
            ? 'OTP गलत है। सही OTP डालें।'
            : error.message ?? 'OTP सत्यापित नहीं हुआ।',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('OTP सत्यापित नहीं हुआ। दोबारा कोशिश करें।');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF5),
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
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'बुकिंग जारी रखने के लिए अपना मोबाइल नंबर सत्यापित करें।',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
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
                  keyboardType: TextInputType.number,
                  maxLength: 6,
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
              ],
              const SizedBox(height: 28),
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
