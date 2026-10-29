import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';

const Color changePhoneOrange = DojoWalkTheme.primary;
const Color changePhoneBackground = DojoWalkTheme.background;

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
    appLocale.removeListener(_onLocaleChanged);
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
        return _tr('Please enter a valid mobile number.', 'कृपया सही मोबाइल नंबर लिखें।', 'সঠিক মোবাইল নম্বর লিখুন।');
      case 'invalid-verification-code':
        return _tr('Incorrect OTP. Please try again.', 'OTP गलत है। दोबारा कोशिश करें।', 'OTP ভুল। আবার চেষ্টা করুন।');
      case 'session-expired':
      case 'invalid-verification-id':
        return _tr('OTP expired. Please request a new OTP.', 'OTP की अवधि समाप्त हो गई। नया OTP माँगें।', 'OTP-এর মেয়াদ শেষ। নতুন OTP চান।');
      case 'too-many-requests':
        return _tr('Too many attempts. Please try again later.', 'बहुत ज़्यादा कोशिशें हुईं। बाद में कोशिश करें।', 'অনেকবার চেষ্টা হয়েছে। পরে আবার চেষ্টা করুন।');
      case 'quota-exceeded':
        return _tr('SMS quota exceeded. Please try later.', 'SMS सीमा पूरी हो गई। बाद में कोशिश करें।', 'SMS সীমা শেষ। পরে চেষ্টা করুন।');
      case 'credential-already-in-use':
      case 'phone-number-already-exists':
        return _tr('This number is already linked to another account.', 'यह नंबर पहले से दूसरे अकाउंट से जुड़ा है।', 'এই নম্বরটি ইতিমধ্যে অন্য অ্যাকাউন্টে যুক্ত।');
      case 'requires-recent-login':
        return _tr('For security, log in again before changing your number.', 'सुरक्षा के लिए नंबर बदलने से पहले दोबारा लॉग इन करें।', 'নিরাপত্তার জন্য নম্বর পরিবর্তনের আগে আবার লগ ইন করুন।');
      case 'network-request-failed':
        return _tr('Check your internet connection and try again.', 'इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।', 'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।');
      case 'operation-not-allowed':
        return _tr('Phone Authentication is not enabled in Firebase.', 'Firebase में Phone Authentication चालू नहीं है।', 'Firebase-এ Phone Authentication চালু নেই।');
      default:
        return error.message ??
            _tr('Something went wrong. Please try again.', 'कुछ गलत हुआ। दोबारा कोशिश करें।', 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।');
    }
  }

  Future<void> _sendOtp() async {
    if (_sending || _updating) return;

    if (!_formKey.currentState!.validate()) return;

    final digits = _phoneController.text.trim();
    final newPhone = '+91$digits';

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _message(_tr('Please log in before changing your number.', 'नंबर बदलने से पहले लॉग इन करें।', 'নম্বর পরিবর্তনের আগে লগ ইন করুন।'));
      return;
    }

    final currentPhone = currentUser.phoneNumber;

    if (currentPhone == newPhone) {
      _message(_tr('This is already your current mobile number.', 'यह आपका मौजूदा मोबाइल नंबर है।', 'এটি আপনার বর্তমান মোবাইল নম্বর।'));
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

          _message(_tr('OTP sent to $newPhone', '$newPhone पर OTP भेज दिया गया', '$newPhone নম্বরে OTP পাঠানো হয়েছে'));
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
      _message(_tr('Could not send OTP. Please try again.', 'OTP नहीं भेजा जा सका। दोबारा कोशिश करें।', 'OTP পাঠানো যায়নি। আবার চেষ্টা করুন।'));
    }
  }

  Future<void> _verifyAndUpdate() async {
    if (_sending || _updating) return;

    final verificationId = _verificationId;
    final phone = _pendingPhoneNumber;
    final otp = _otpController.text.trim();

    if (verificationId == null || phone == null) {
      _message(_tr('First request an OTP for your new number.', 'पहले नए नंबर के लिए OTP माँगें।', 'আগে নতুন নম্বরের জন্য OTP চান।'));
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _message(_tr('Enter the 6-digit OTP.', '6 अंकों का OTP लिखें।', '৬ সংখ্যার OTP লিখুন।'));
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
      _message(_tr('Your login session has expired. Please log in again.', 'लॉगिन सत्र समाप्त हो गया। दोबारा लॉग इन करें।', 'লগইন সেশন শেষ। আবার লগ ইন করুন।'));
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

      _message(_tr('Mobile number updated successfully.', 'मोबाइल नंबर अपडेट हो गया।', 'মোবাইল নম্বর আপডেট হয়েছে।'));

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _updating = false);
      _message(_friendlyError(error));
    } catch (_) {
      if (!mounted) return;

      setState(() => _updating = false);
      _message(
        _tr('The update could not be completed. Please check your connection and account details before trying again.', 'अपडेट पूरा नहीं हुआ। दोबारा कोशिश करने से पहले कनेक्शन और अकाउंट विवरण जाँचें।', 'আপডেট সম্পন্ন হয়নি। আবার চেষ্টা করার আগে সংযোগ ও অ্যাকাউন্টের তথ্য পরীক্ষা করুন।'),
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
        title: Text(
          _tr('Update Mobile Number', 'मोबाइल नंबर अपडेट करें', 'মোবাইল নম্বর আপডেট করুন'),
          style: TextStyle(
            color: Color(0xFF252525),
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
            Text(
              _tr('Verify Your New Number', 'अपने नए नंबर की पुष्टि करें', 'আপনার নতুন নম্বর যাচাই করুন'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Color(0xFF252525),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tr('Enter your new Indian mobile number. We will send an OTP to verify it before updating your existing account.', 'अपना नया भारतीय मोबाइल नंबर लिखें। मौजूदा अकाउंट अपडेट करने से पहले OTP से पुष्टि होगी।', 'আপনার নতুন ভারতীয় মোবাইল নম্বর লিখুন। বর্তমান অ্যাকাউন্ট আপডেটের আগে OTP দিয়ে যাচাই করা হবে।'),
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
                  Text(
                    _tr('New Mobile Number', 'नया मोबाइल नंबर', 'নতুন মোবাইল নম্বর'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF252525),
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
                      hintText: _tr('Enter 10-digit number', '10 अंकों का नंबर लिखें', '১০ সংখ্যার নম্বর লিখুন'),
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
                        return _tr('Enter a valid 10-digit Indian number.', 'सही 10 अंकों का भारतीय नंबर लिखें।', 'সঠিক ১০ সংখ্যার ভারতীয় নম্বর লিখুন।');
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
                                  ? _tr('Send OTP', 'OTP भेजें', 'OTP পাঠান')
                                  : _tr('OTP Sent', 'OTP भेज दिया गया', 'OTP পাঠানো হয়েছে'),
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
              Text(
                _tr('Enter 6-Digit OTP', '6 अंकों का OTP लिखें', '৬ সংখ্যার OTP লিখুন'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF252525),
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
                  hintText: _tr('Enter OTP', 'OTP लिखें', 'OTP লিখুন'),
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
                      : Text(
                          _tr('Verify & Update Number', 'पुष्टि करें और नंबर अपडेट करें', 'যাচাই করে নম্বর আপডেট করুন'),
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
                child: Text(
                  _tr('Use a different number', 'दूसरा नंबर इस्तेमाल करें', 'অন্য নম্বর ব্যবহার করুন'),
                  style: TextStyle(color: changePhoneOrange),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
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
                    _tr('Your existing account is updated only after OTP verification. This screen does not create a new account.', 'आपका मौजूदा अकाउंट OTP पुष्टि के बाद ही अपडेट होता है। यह स्क्रीन नया अकाउंट नहीं बनाती।', 'OTP যাচাইয়ের পরই আপনার বর্তমান অ্যাকাউন্ট আপডেট হয়। এই স্ক্রিন নতুন অ্যাকাউন্ট তৈরি করে না.'),
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
