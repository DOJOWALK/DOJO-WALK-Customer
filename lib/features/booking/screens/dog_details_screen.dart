
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_start_screen.dart';
import 'pickup_address_screen.dart';

const Color dogDetailsOrange = Color(0xFFFF7900);
const Color dogDetailsBackground = Color(0xFFFFFAF5);
const Color dogDetailsText = Color(0xFF202020);

class DogDetailsScreen extends StatefulWidget {
  const DogDetailsScreen({
    super.key,
    required this.walkType,
  });

  final WalkBookingType walkType;

  @override
  State<DogDetailsScreen> createState() => _DogDetailsScreenState();
}

class _DogDetailsScreenState extends State<DogDetailsScreen> {
  String? _selectedDogId;
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _pets(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addDog() async {
    final user = _user;

    if (user == null) {
      _showMessage('Please log in before adding a dog.');
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddDogSheet(),
    );

    if (result == null || !mounted) return;

    setState(() => _saving = true);

    try {
      final doc = await _pets(user.uid).add({
        ...result,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _selectedDogId = doc.id;
        _saving = false;
      });

      _showMessage('${result['name']} saved successfully.');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        e.code == 'permission-denied'
            ? 'Permission denied. Please check your Firebase rules.'
            : e.message ?? 'Could not save dog. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save dog. Please try again.');
    }
  }

  void _continue(Map<String, dynamic> dogDetails) {
    final dogId = _selectedDogId;

    if (dogId == null) {
      _showMessage('Please select a dog first.');
      return;
    }

    // Keep existing fields and add the real Firestore document ID.
    final selectedDog = <String, dynamic>{
      ...dogDetails,
      'dogId': dogId,
    };

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PickupAddressScreen(
          walkType: widget.walkType,
          dogDetails: selectedDog,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return Scaffold(
        backgroundColor: dogDetailsBackground,
        appBar: AppBar(
          backgroundColor: dogDetailsBackground,
          title: const Text('Choose Your Dog'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Please log in to select or add your saved dog.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: dogDetailsBackground,
      appBar: AppBar(
        backgroundColor: dogDetailsBackground,
        elevation: 0,
        title: const Text(
          'Choose Your Dog',
          style: TextStyle(
            color: dogDetailsText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _pets(user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load your dogs. Please check your '
                    'internet connection and Firebase permissions.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: dogDetailsOrange,
                ),
              );
            }

            final dogs = snapshot.data?.docs ?? [];

            final selectedExists = dogs.any(
              (doc) => doc.id == _selectedDogId,
            );

            if (!selectedExists && dogs.isNotEmpty) {
              // Keep selection valid if a dog was removed.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedDogId != null) {
                  setState(() => _selectedDogId = null);
                }
              });
            }

            final selectedDoc = dogs.where(
              (doc) => doc.id == _selectedDogId,
            ).firstOrNull;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                const Text(
                  'Which dog is going for a walk?',
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: dogDetailsText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a saved dog. You can add another dog '
                  'whenever you need.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 22),

                if (dogs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE7E7E7),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.pets_rounded,
                          color: dogDetailsOrange,
                          size: 44,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No saved dogs yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add your dog once. You can select it '
                          'again for future bookings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                ...dogs.map((doc) {
                  final data = doc.data();
                  final selected = doc.id == _selectedDogId;
                  final name = (data['name'] ?? 'Unnamed dog').toString();
                  final breed = (data['breed'] ?? '').toString();
                  final size = (data['size'] ?? '').toString();
                  final gender = (data['gender'] ?? '').toString();

                  final details = [
                    breed,
                    size,
                    if (gender.isNotEmpty && gender != 'Not specified')
                      gender,
                  ].where((value) => value.trim().isNotEmpty).join(' · ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedDogId = doc.id);
                      },
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: selected
                                ? dogDetailsOrange
                                : const Color(0xFFE7E7E7),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: dogDetailsOrange.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                color: dogDetailsOrange,
                                size: 29,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: dogDetailsText,
                                    ),
                                  ),
                                  if (details.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      details,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                  if ((data['notes'] ?? '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Care instructions saved',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected
                                  ? dogDetailsOrange
                                  : Colors.black38,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 4),

                OutlinedButton.icon(
                  onPressed: _saving ? null : _addDog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add a New Dog'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dogDetailsOrange,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: dogDetailsOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving || selectedDoc == null
                        ? null
                        : () => _continue(selectedDoc.data()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dogDetailsOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          dogDetailsOrange.withValues(alpha: 0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Pickup Address',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddDogSheet extends StatefulWidget {
  const _AddDogSheet();

  @override
  State<_AddDogSheet> createState() => _AddDogSheetState();
}

class _AddDogSheetState extends State<_AddDogSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _age = TextEditingController();
  final _notes = TextEditingController();

  String _size = 'Medium';
  String _gender = 'Not specified';

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(<String, dynamic>{
      'name': _name.text.trim(),
      'breed': _breed.text.trim(),
      'age': _age.text.trim(),
      'size': _size,
      'gender': _gender,
      'notes': _notes.text.trim(),
    });
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: dogDetailsBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: dogDetailsOrange,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _label(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add a New Dog',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: dogDetailsText,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Save these details for future bookings.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),

                _label('Dog name *'),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('e.g. Bruno'),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Enter your dog’s name';
                    if (name.length > 50) {
                      return 'Name must be under 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _label('Breed'),
                TextFormField(
                  controller: _breed,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('e.g. Labrador or Indie'),
                ),
                const SizedBox(height: 15),

                _label('Age in years'),
                TextFormField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('e.g. 2'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final age = int.tryParse(text);
                    if (age == null || age < 0 || age > 40) {
                      return 'Enter a whole number from 0 to 40';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _label('Dog size *'),
                DropdownButtonFormField<String>(
                  initialValue: _size,
                  isExpanded: true,
                  decoration: _decoration('Select size'),
                  items: const [
                    DropdownMenuItem(value: 'Small', child: Text('Small')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Large', child: Text('Large')),
                    DropdownMenuItem(
                      value: 'Extra Large',
                      child: Text('Extra Large'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _size = value);
                  },
                ),
                const SizedBox(height: 15),

                _label('Gender'),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  isExpanded: true,
                  decoration: _decoration('Select gender'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Not specified',
                      child: Text('Prefer not to specify'),
                    ),
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _gender = value);
                  },
                ),
                const SizedBox(height: 15),

                _label('Special instructions (optional)'),
                TextFormField(
                  controller: _notes,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: _decoration(
                    'Behaviour, leash needs, fears or care instructions',
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dogDetailsOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Dog',
                      style: TextStyle(fontWeight: FontWeight.w800),
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
