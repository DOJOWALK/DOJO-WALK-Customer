
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_navigator.dart';

const Color profileOrange = Color(0xFFFF7900);
const Color profileBackground = Color(0xFFFFFAF5);

class NameSetupScreen extends StatefulWidget {
  const NameSetupScreen({super.key});

  @override
  State<NameSetupScreen> createState() => _NameSetupScreenState();
}

class _NameSetupScreenState extends State<NameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _gender;
  DateTime? _dateOfBirth;
  File? _selectedPhoto;
  String? _photoUrl;

  bool _loading = true;
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
      ),
    );
  }

  Future<void> _loadExistingProfile() async {
    try {
      final user = _user;

      if (user == null) {
        _showMessage('Please log in with your mobile number.');
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data() ?? {};

        _nameController.text = (data['name'] ?? '').toString();

        final savedGender = data['gender'];
        if (savedGender is String &&
            ['male', 'female', 'other'].contains(savedGender)) {
          _gender = savedGender;
        }

        final savedDob = data['dateOfBirth'];

        if (savedDob is Timestamp) {
          _dateOfBirth = savedDob.toDate();
        } else if (savedDob is String) {
          _dateOfBirth = DateTime.tryParse(savedDob);
        }

        final savedPhoto = data['photoUrl'];
        if (savedPhoto is String && savedPhoto.isNotEmpty) {
          _photoUrl = savedPhoto;
        }
      }
    } catch (e) {
      _showMessage('Unable to load profile: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final defaultDate = DateTime(now.year - 18, now.month, 1);
    final currentDate = _dateOfBirth ?? defaultDate;

    final initialDate =
        currentDate.isAfter(today) ? today : currentDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: today,
      helpText: 'Select Date of Birth',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
      initialEntryMode: DatePickerEntryMode.calendar,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: profileOrange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _selectPhoto() async {
    if (_saving) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (picked != null && mounted) {
        setState(() => _selectedPhoto = File(picked.path));
      }
    } catch (e) {
      _showMessage('Unable to select photo: $e');
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_selectedPhoto == null) return _photoUrl;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('customer_profiles')
        .child(uid)
        .child('profile.jpg');

    final uploadTask = await storageRef.putFile(
      _selectedPhoto!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return uploadTask.ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (_saving || _loading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      _showMessage('Please select your gender.');
      return;
    }

    if (_dateOfBirth == null) {
      _showMessage('Please select your date of birth.');
      return;
    }

    final user = _user;

    if (user == null) {
      _showMessage('Please log in with your mobile number.');
      return;
    }

    setState(() => _saving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final profileRef = firestore.collection('users').doc(user.uid);

      final existing = await profileRef.get();

      if (!mounted) return;

      final uploadedPhotoUrl = await _uploadPhoto(user.uid);

      if (!mounted) return;

      final selectedDob = _dateOfBirth!;

      final profileData = <String, dynamic>{
        'uid': user.uid,
        'role': 'customer',
        'name': _nameController.text.trim(),
        'gender': _gender,
        'dateOfBirth': Timestamp.fromDate(
          DateTime(
            selectedDob.year,
            selectedDob.month,
            selectedDob.day,
          ),
        ),
        'phoneNumber': user.phoneNumber ?? '',
        'photoUrl': uploadedPhotoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
      }

      await profileRef.set(
        profileData,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const AppNavigator(),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Unable to save profile: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        backgroundColor: profileBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Set Up Your Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: profileOrange,
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Welcome to DOJO WALK!',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your details to set up your customer account.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),

                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _saving ? null : _selectPhoto,
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFFFFE3CC),
                              backgroundImage: _selectedPhoto != null
                                  ? FileImage(_selectedPhoto!)
                                  : (_photoUrl != null
                                      ? NetworkImage(_photoUrl!)
                                      : null) as ImageProvider?,
                              child: _selectedPhoto == null &&
                                      _photoUrl == null
                                  ? const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 34,
                                      color: profileOrange,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _saving ? null : _selectPhoto,
                            child: const Text(
                              'Add Profile Photo (Optional)',
                              style: TextStyle(color: profileOrange),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Customer Name *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      decoration: _decoration(
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name.';
                        }

                        if (value.trim().length < 2) {
                          return 'Name must contain at least 2 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Gender *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: _decoration(
                        hint: 'Select gender',
                        icon: Icons.person_search_outlined,
                      ),
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
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _gender = value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your gender.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Date of Birth *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _saving ? null : _selectDateOfBirth,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _decoration(
                          hint: 'Select your date of birth',
                          icon: Icons.calendar_month_outlined,
                        ),
                        child: Text(
                          _dateOfBirth == null
                              ? 'Select Date'
                              : _formatDate(_dateOfBirth!),
                          style: TextStyle(
                            color: _dateOfBirth == null
                                ? Colors.black54
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: profileOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                                'Save & Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: profileOrange),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE8E0D9),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE8E0D9),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: profileOrange,
          width: 1.5,
        ),
      ),
    );
  }
}
