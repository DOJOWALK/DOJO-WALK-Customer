
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'change_mobile_number_screen.dart';
import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';

const Color accountOrange = DojoWalkTheme.primary;
const Color accountBackground = DojoWalkTheme.background;
const Color accountText = DojoWalkTheme.text;
const Color accountMuted = DojoWalkTheme.mutedText;

class AccountDetailsScreen extends StatefulWidget {
  final User user;

  const AccountDetailsScreen({
    super.key,
    required this.user,
  });

  @override
  State<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _loadError = false;
  bool _profileLoaded = false;

  String _phone = '';
  String _gender = '';
  String _photoUrl = '';
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_onLocaleChanged);
    _loadProfile();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  String _tr(String en, String hi, String bn) =>
      appText(en: en, hi: hi, bn: bn);

  @override
  void dispose() {
    appLocale.removeListener(_onLocaleChanged);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = false;
      });
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      final data = doc.data() ?? {};
      _profileLoaded = true;

      _nameController.text = data['name'] is String
          ? data['name'] as String
          : widget.user.displayName ?? '';

      _phone = data['phoneNumber'] is String
          ? data['phoneNumber'] as String
          : widget.user.phoneNumber ?? '';

      final gender = data['gender'];
      _gender = gender is String &&
              ['male', 'female', 'other'].contains(gender)
          ? gender
          : '';

      _photoUrl = data['photoUrl'] is String
          ? data['photoUrl'] as String
          : '';

      final dob = data['dateOfBirth'];

      if (dob is Timestamp) {
        _dateOfBirth = dob.toDate();
      } else if (dob is String) {
        _dateOfBirth = DateTime.tryParse(dob);
      }
    } catch (_) {
      _profileLoaded = false;
      if (mounted) setState(() => _loadError = true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  DateTime _latestAllowedDob() {
    final now = DateTime.now();
    final year = now.year - 18;

    // Handles leap-day dates safely.
    final day = now.month == 2 && now.day == 29
        ? 28
        : now.day;

    return DateTime(year, now.month, day);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return _tr('Select date of birth', 'जन्म तिथि चुनें', 'জন্মতারিখ বেছে নিন');

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _selectDob() async {
    final latest = _latestAllowedDob();

    final initial = _dateOfBirth != null &&
            !_dateOfBirth!.isAfter(latest) &&
            !_dateOfBirth!.isBefore(DateTime(1920))
        ? _dateOfBirth!
        : latest;

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: latest,
      helpText: _tr('Select your date of birth', 'अपनी जन्म तिथि चुनें', 'আপনার জন্মতারিখ বেছে নিন'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: accountOrange,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Future<void> _saveProfile() async {
    if (_loadError || !_profileLoaded || _loading || _saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      _message(_tr('Please select your date of birth.', 'कृपया अपनी जन्म तिथि चुनें।', 'আপনার জন্মতারিখ বেছে নিন।'));
      return;
    }

    if (_dateOfBirth!.isAfter(_latestAllowedDob())) {
      _message(_tr('You must be at least 18 years old.', 'आपकी उम्र कम से कम 18 वर्ष होनी चाहिए।', 'আপনার বয়স কমপক্ষে ১৮ বছর হতে হবে।'));
      return;
    }

    if (!['male', 'female', 'other'].contains(_gender)) {
      _message(_tr('Please select your gender.', 'कृपया लिंग चुनें।', 'লিঙ্গ বেছে নিন।'));
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'name': _nameController.text.trim(),
        'gender': _gender,
        'dateOfBirth': Timestamp.fromDate(_dateOfBirth!),
        'phoneNumber': _phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _message(_tr('Account details saved successfully.', 'अकाउंट की जानकारी सेव हो गई।', 'অ্যাকাউন্টের তথ্য সফলভাবে সংরক্ষিত হয়েছে।'));
    } catch (_) {
      if (!mounted) return;
      _message(_tr('Could not save details. Please try again.', 'जानकारी सेव नहीं हुई। दोबारा कोशिश करें।', 'তথ্য সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openMobileUpdate() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ChangeMobileNumberScreen(),
      ),
    );

    if (updated == true && mounted) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accountBackground,
      appBar: AppBar(
        backgroundColor: accountBackground,
        elevation: 0,
        title: Text(
          _tr('Account Details', 'अकाउंट की जानकारी', 'অ্যাকাউন্টের তথ্য'),
          style: TextStyle(
            color: accountText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: accountOrange,
              ),
            )
          : _loadError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 44, color: accountMuted),
                        const SizedBox(height: 14),
                        Text(
                          _tr(
                            'We could not load your account details. Your information has not been changed.',
                            'अकाउंट की जानकारी लोड नहीं हो सकी। आपकी जानकारी में कोई बदलाव नहीं किया गया है।',
                            'অ্যাকাউন্টের তথ্য লোড করা যায়নি। আপনার তথ্য পরিবর্তন করা হয়নি।',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: accountText, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(_tr('Try Again', 'फिर से कोशिश करें', 'আবার চেষ্টা করুন')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accountOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Center(
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAD8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: _photoUrl.isNotEmpty
                            ? Image.network(
                                _photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: accountOrange,
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: accountOrange,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _tr('Your personal information', 'आपकी व्यक्तिगत जानकारी', 'আপনার ব্যক্তিগত তথ্য'),
                      style: TextStyle(color: accountMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label(_tr('Full Name', 'पूरा नाम', 'পুরো নাম')),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration(_tr('Enter your full name', 'अपना पूरा नाम लिखें', 'আপনার পুরো নাম লিখুন')),
                    validator: (value) {
                      if (value == null ||
                          value.trim().length < 2) {
                        return _tr('Enter at least 2 characters.', 'कम से कम 2 अक्षर लिखें।', 'কমপক্ষে ২টি অক্ষর লিখুন।');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tr('Mobile Number', 'मोबाइल नंबर', 'মোবাইল নম্বর'),
                          style: TextStyle(
                            color: accountText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openMobileUpdate,
                        child: Text(
                          _tr('Update', 'अपडेट करें', 'আপডেট করুন'),
                          style: TextStyle(
                            color: accountOrange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFED),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_android_rounded,
                          color: accountMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _phone.isEmpty
                                ? _tr('Number not available', 'नंबर उपलब्ध नहीं है', 'নম্বর পাওয়া যায়নি')
                                : _phone,
                            style: const TextStyle(
                              color: accountText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label(_tr('Date of Birth', 'जन्म तिथि', 'জন্মতারিখ')),
                  InkWell(
                    onTap: _selectDob,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE4DDD6),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: accountOrange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDate(_dateOfBirth),
                              style: TextStyle(
                                color: _dateOfBirth == null
                                    ? accountMuted
                                    : accountText,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: accountMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label(_tr('Gender', 'लिंग', 'লিঙ্গ')),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _gender.isEmpty ? null : _gender,
                    decoration: _decoration(_tr('Select gender', 'लिंग चुनें', 'লিঙ্গ বেছে নিন')),
                    items: [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text(_tr('Male', 'पुरुष', 'পুরুষ')),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text(_tr('Female', 'महिला', 'মহিলা')),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text(_tr('Other', 'अन्य', 'অন্যান্য')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _gender = value ?? '');
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _tr('Please select your gender.', 'कृपया लिंग चुनें।', 'লিঙ্গ বেছে নিন।');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accountOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _tr('Save Changes', 'बदलाव सेव करें', 'পরিবর্তন সংরক্ষণ করুন'),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: accountText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4DDD6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: accountOrange,
          width: 1.5,
        ),
      ),
    );
  }
}
