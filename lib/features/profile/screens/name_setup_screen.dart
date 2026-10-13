
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
  final String? bookingWalkType;

  const NameSetupScreen({
    super.key,
    this.bookingWalkType,
  });

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
  String? _loadError;

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

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    var age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age;
  }

  DateTime? _parseDateOfBirth(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _loadExistingProfile() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = _user;

      if (user == null) {
        setState(() {
          _loadError =
              'Please log in with your mobile number first.';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data() ?? <String, dynamic>{};

        _nameController.text = (data['name'] ?? '').toString();

        final savedGender = data['gender'];
        if (savedGender is String &&
            ['male', 'female', 'other'].contains(savedGender)) {
          _gender = savedGender;
        }

        final dob = _parseDateOfBirth(data['dateOfBirth']);
        if (dob != null && !dob.isAfter(DateTime.now())) {
          _dateOfBirth = dob;
        }

        final photo = data['photoUrl'];
        if (photo is String && photo.isNotEmpty) {
          _photoUrl = photo;
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError =
              'Unable to load your profile. Please check your internet connection.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    if (_saving) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final latestAllowedDate = DateTime(
      today.year - 18,
      today.month,
      today.day,
    );

    final initialDate =
        _dateOfBirth != null &&
                !_dateOfBirth!.isAfter(latestAllowedDate)
            ? _dateOfBirth!
            : latestAllowedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: latestAllowedDate,
      helpText: 'SELECT DATE OF BIRTH',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
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
    } catch (_) {
      _showMessage('Unable to select the photo. Please try again.');
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

    await storageRef.putFile(
      _selectedPhoto!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return storageRef.getDownloadURL();
  }

  void _navigateAfterSave() {
    if (widget.bookingWalkType != null) {
      // Return success to PhoneLoginScreen.
      // PhoneLoginScreen then returns success to ChooseWalkScreen,
      // which opens WalkScheduleScreen with the selected walk type.
      Navigator.of(context).pop(true);
      return;
    }

    // Normal profile completion goes to the main application.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AppNavigator(),
      ),
      (route) => false,
    );
  }

  Future<void> _saveProfile() async {
    if (_saving || _loading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      _showMessage('Please select your gender.');
      return;
    }

    if (_dateOfBirth == null) {
      _showMessage('Please select your date of birth.');
      return;
    }

    final dob = _dateOfBirth!;
    final now = DateTime.now();

    if (dob.isAfter(now)) {
      _showMessage('Date of birth cannot be in the future.');
      return;
    }

    if (_calculateAge(dob) < 18) {
      _showMessage(
        'You must be at least 18 years old to create a DOJO WALK account.',
      );
      return;
    }

    final user = _user;

    if (user == null) {
      _showMessage('Your session has expired. Please log in again.');
      return;
    }

    setState(() => _saving = true);

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final existingSnapshot = await userRef.get();
      final existingData =
          existingSnapshot.data() ?? <String, dynamic>{};

      final uploadedPhotoUrl = await _uploadPhoto(user.uid);

      final profileData = <String, dynamic>{
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'gender': _gender,
        'dateOfBirth': Timestamp.fromDate(dob),
        'phoneNumber': user.phoneNumber ?? '',
        'photoUrl': uploadedPhotoUrl ?? '',
        'role': 'customer',
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existingSnapshot.exists ||
          existingData['createdAt'] == null) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
      }

      await userRef.set(
        profileData,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      _navigateAfterSave();
    } on FirebaseException catch (error) {
      _showMessage(
        'Unable to save your profile. Please check your connection. (${error.code})',
      );
    } catch (_) {
      _showMessage(
        'Unable to save your profile. Please check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: profileOrange),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E0D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E0D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: profileOrange,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    ImageProvider? imageProvider;

    if (_selectedPhoto != null) {
      imageProvider = FileImage(_selectedPhoto!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_photoUrl!);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 49,
                backgroundColor: const Color(0xFFFFE7D2),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: profileOrange,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: profileOrange,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _saving ? null : _selectPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _saving ? null : _selectPhoto,
            child: const Text(
              'Add Profile Photo (Optional)',
              style: TextStyle(
                color: profileOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _genderOption('male', 'Male', Icons.male_rounded),
            const SizedBox(width: 8),
            _genderOption('female', 'Female', Icons.female_rounded),
            const SizedBox(width: 8),
            _genderOption('other', 'Other', Icons.person_outline),
          ],
        ),
      ],
    );
  }

  Widget _genderOption(
    String value,
    String label,
    IconData icon,
  ) {
    final selected = _gender == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _saving
            ? null
            : () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFE7D2)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? profileOrange
                  : const Color(0xFFE8E0D8),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? profileOrange : Colors.black54,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? profileOrange : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _saving ? null : _selectDateOfBirth,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Date of Birth',
          icon: Icons.calendar_month_outlined,
          hint: 'DD/MM/YYYY',
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dateOfBirth == null
                    ? 'Select your date of birth'
                    : _formatDate(_dateOfBirth!),
                style: TextStyle(
                  color: _dateOfBirth == null
                      ? Colors.black45
                      : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhotoPicker(),
          const SizedBox(height: 22),
          const Text(
            'Your Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 60,
            decoration: _inputDecoration(
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              hint: 'Enter your full name',
            ).copyWith(counterText: ''),
            validator: (value) {
              final name = value?.trim() ?? '';

              if (name.isEmpty) return 'Please enter your name.';
              if (name.length < 2) {
                return 'Name must be at least 2 characters.';
              }
              if (name.length > 60) {
                return 'Name cannot exceed 60 characters.';
              }

              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildGenderSelector(),
          const SizedBox(height: 20),
          _buildDatePicker(),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: Colors.black54,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'You must be at least 18 years old to create a DOJO WALK account.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: profileOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.orange.shade200,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 23,
                      width: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save and Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your information helps us provide a safer and more reliable dog-walking experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        backgroundColor: profileBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: profileOrange,
                ),
              )
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 48,
                            color: profileOrange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _loadExistingProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: profileOrange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      30,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.pets_rounded,
                            color: profileOrange,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Welcome to DOJO WALK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Tell us a little about yourself to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildProfileForm(),
                      ],
                    ),
                  ),
      ),
    );
  }
}
