
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'change_mobile_number_screen.dart';

const Color accountOrange = Color(0xFFFF7900);
const Color accountBackground = Color(0xFFFFFAF5);
const Color accountText = Color(0xFF202020);
const Color accountMuted = Color(0xFF777777);

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

  String _phone = '';
  String _gender = '';
  String _photoUrl = '';
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      final data = doc.data() ?? {};

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
      _nameController.text = widget.user.displayName ?? '';
      _phone = widget.user.phoneNumber ?? '';
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
    if (date == null) return 'Select date of birth';

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
      helpText: 'Select your date of birth',
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
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      _message('Please select your date of birth.');
      return;
    }

    if (_dateOfBirth!.isAfter(_latestAllowedDob())) {
      _message('You must be at least 18 years old.');
      return;
    }

    if (!['male', 'female', 'other'].contains(_gender)) {
      _message('Please select your gender.');
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
      _message('Account details saved successfully.');
    } catch (_) {
      if (!mounted) return;
      _message('Could not save details. Please try again.');
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
      setState(() => _loading = true);
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
        title: const Text(
          'Account Details',
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
                  const Center(
                    child: Text(
                      'Your personal information',
                      style: TextStyle(color: accountMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _label('Full Name'),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration('Enter your full name'),
                    validator: (value) {
                      if (value == null ||
                          value.trim().length < 2) {
                        return 'Enter at least 2 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mobile Number',
                          style: TextStyle(
                            color: accountText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openMobileUpdate,
                        child: const Text(
                          'Update',
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
                                ? 'Number not available'
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
                  _label('Date of Birth'),
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
                  _label('Gender'),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _gender.isEmpty ? null : _gender,
                    decoration: _decoration('Select gender'),
                    items: const [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _gender = value ?? '');
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender.';
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
                          : const Text(
                              'Save Changes',
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
