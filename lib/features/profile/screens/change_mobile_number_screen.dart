import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color changePhoneOrange = Color(0xFFFF7900);
const Color changePhoneBackground = Color(0xFFFFFAF5);

class ChangeMobileNumberScreen extends StatefulWidget {
  const ChangeMobileNumberScreen({super.key});

  @override
  State<ChangeMobileNumberScreen> createState() =>
      _ChangeMobileNumberScreenState();
}

class _ChangeMobileNumberScreenState
    extends State<ChangeMobileNumberScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  String? _pendingPhoneNumber;

  bool _sending = false;
  bool _updating = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Please enter a valid mobile number.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please try again.';
      case 'session-expired':
      case 'invalid-verification-id':
        return 'OTP expired. Please request a new OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try later.';
      case 'credential-already-in-use':
      case 'phone-number-already-exists':
        return 'This number is already linked to another account.';
      case 'requires-recent-login':
        return 'For security, log in again before changing your number.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Phone Authentication is not enabled in Firebase.';
      default:
        return error.message ??
            'Something went wrong. Please try again.';
    }
  }

  Future<void> _sendOtp() async {
    if (_sending || _updating) return;

    if (!_formKey.currentState!.validate()) return;

    final digits = _phoneController.text.trim();
    final newPhone = '+91$digits';

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _message('Please log in before changing your number.');
      return;
    }

    final currentPhone = currentUser.phoneNumber;

    if (currentPhone == newPhone) {
      _message('This is already your current mobile number.');
      return;
    }

    setState(() {
      _sending = true;
      _verificationId = null;
      _pendingPhoneNumber = newPhone;
      _otpController.clear();
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: newPhone,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) {
          _updateExistingAccount(credential, newPhone);
        },

        verificationFailed: (FirebaseAuthException error) {
          if (!mounted) return;
          setState(() => _sending = false);
          _message(_friendlyError(error));
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _sending = false;
          });

          _message('OTP sent to $newPhone');
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _sending = false;
          });
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      _message(_friendlyError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _message('Could not send OTP. Please try again.');
    }
  }

  Future<void> _verifyAndUpdate() async {
    if (_sending || _updating) return;

    final verificationId = _verificationId;
    final phone = _pendingPhoneNumber;
    final otp = _otpController.text.trim();

    if (verificationId == null || phone == null) {
      _message('First request an OTP for your new number.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _message('Enter the 6-digit OTP.');
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    await _updateExistingAccount(credential, phone);
  }

  Future<void> _updateExistingAccount(
    PhoneAuthCredential credential,
    String newPhone,
  ) async {
    if (_updating) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _message('Your login session has expired. Please log in again.');
      return;
    }

    setState(() {
      _updating = true;
      _sending = false;
    });

    try {
      // Update the currently signed-in Firebase account.
      // Do not sign in or create a separate account here.
      await currentUser.updatePhoneNumber(credential);

      // Keep the existing DOJO WALK Firestore user document in sync.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'phoneNumber': newPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _message('Mobile number updated successfully.');

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _updating = false);
      _message(_friendlyError(error));
    } catch (_) {
      if (!mounted) return;

      setState(() => _updating = false);
      _message(
        'The update could not be completed. Please check your connection '
        'and account details before trying again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: changePhoneBackground,
      appBar: AppBar(
        backgroundColor: changePhoneBackground,
        elevation: 0,
        title: const Text(
          'Update Mobile Number',
          style: TextStyle(
            color: Color(0xFF202020),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 12),
            const Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFFFEAD8),
                child: Icon(
                  Icons.phonelink_lock_rounded,
                  size: 43,
                  color: changePhoneOrange,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verify Your New Number',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Color(0xFF202020),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your new Indian mobile number. We will send an OTP '
              'to verify it before updating your existing account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF777777),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Mobile Number',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_sending && !_updating &&
                        _verificationId == null,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      prefixText: '+91  ',
                      hintText: 'Enter 10-digit number',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: changePhoneOrange,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[6-9]\d{9}$')
                              .hasMatch(value.trim())) {
                        return 'Enter a valid 10-digit Indian number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _sending || _updating
                          ? null
                          : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: changePhoneOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _verificationId == null
                                  ? 'Send OTP'
                                  : 'OTP Sent',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_verificationId != null) ...[
              const SizedBox(height: 28),
              const Text(
                'Enter 6-Digit OTP',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202020),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                enabled: !_updating,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
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
                      color: changePhoneOrange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _updating ? null : _verifyAndUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: changePhoneOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _updating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify & Update Number',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _sending || _updating
                    ? null
                    : () {
                        setState(() {
                          _verificationId = null;
                          _pendingPhoneNumber = null;
                          _otpController.clear();
                        });
                      },
                child: const Text(
                  'Use a different number',
                  style: TextStyle(color: changePhoneOrange),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: changePhoneOrange,
                  size: 20,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Your existing account is updated only after OTP '
                    'verification. This screen does not create a new account.',
                    style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
