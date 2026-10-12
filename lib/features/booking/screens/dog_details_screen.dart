
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_start_screen.dart';
import 'pickup_address_screen.dart';

const Color dogDetailsOrange = Color(0xFFFF7900);
const Color dogDetailsBackground = Color(0xFFFFFAF5);
const Color dogDetailsText = Color(0xFF202020);

const List<String> _dogBreeds = [
  'Labrador Retriever',
  'Golden Retriever',
  'German Shepherd',
  'Beagle',
  'Pug',
  'Poodle',
  'Rottweiler',
  'Shih Tzu',
  'Dachshund',
  'Doberman',
  'Boxer',
  'Siberian Husky',
  'Indian Pariah / Indie',
  'Mixed Breed',
  'Other',
];

const List<String> _dogAges = [
  'Under 1 year',
  '1 year',
  '2 years',
  '3 years',
  '4 years',
  '5 years',
  '6 years',
  '7 years',
  '8 years',
  '9 years',
  '10 years',
  '11 years',
  '12 years',
  '13 years',
  '14 years',
  '15+ years',
];

const List<String> _dogSizes = [
  'Small',
  'Medium',
  'Large',
  'Extra Large',
];

const List<String> _dogGenders = [
  'Male',
  'Female',
  'Not specified',
];

const List<String> _dogBehaviours = [
  'Friendly',
  'Calm',
  'Active / Energetic',
  'Shy / Nervous',
  'Pulls on leash',
  'Reactive toward dogs',
  'Barks frequently',
  'Needs experienced walker',
];

const List<String> _dogCareOptions = [
  'Senior dog',
  'Puppy',
  'Injury / Recovery',
  'Medication needed',
  'Feeding instructions',
  'Extra supervision',
];

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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
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

  String _value(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    return [];
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

            final selectedDogs = dogs
                .where((doc) => doc.id == _selectedDogId)
                .toList();

            final selectedDoc =
                selectedDogs.isEmpty ? null : selectedDogs.first;

            if (_selectedDogId != null && selectedDoc == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedDogId != null) {
                  setState(() => _selectedDogId = null);
                }
              });
            }

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
                  'Choose one of your saved dogs. Add a dog only once '
                  'and reuse its details for future bookings.',
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
                          'Add your dog to continue with your booking.',
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

                  final name = _value(data['name']).isEmpty
                      ? 'Unnamed dog'
                      : _value(data['name']);

                  final breed = _value(data['breed']);
                  final age = _value(data['age']);
                  final size = _value(data['size']);
                  final gender = _value(data['gender']);

                  final details = [
                    if (breed.isNotEmpty) breed,
                    if (age.isNotEmpty) age,
                    if (size.isNotEmpty) size,
                    if (gender.isNotEmpty && gender != 'Not specified')
                      gender,
                  ].join(' · ');

                  final behaviour = _stringList(data['behaviour']);
                  final specialCare = _stringList(data['specialCare']);

                  final hasLegacyNotes =
                      _value(data['notes']).isNotEmpty;

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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                  if (behaviour.isNotEmpty) ...[
                                    const SizedBox(height: 9),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: behaviour.map((item) {
                                        return _DogInfoChip(
                                          label: item,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                  if (specialCare.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Special care: ${specialCare.join(', ')}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                  if (hasLegacyNotes) ...[
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Older care instructions saved',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                    side: const BorderSide(
                      color: dogDetailsOrange,
                    ),
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

class _DogInfoChip extends StatelessWidget {
  const _DogInfoChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: dogDetailsBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD5B0),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: dogDetailsText,
          fontWeight: FontWeight.w600,
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

  String? _breed;
  String? _age;
  String _size = 'Medium';
  String _gender = 'Not specified';

  final Set<String> _behaviour = {};
  final Set<String> _specialCare = {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_breed == null || _age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your dog’s breed and age.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(<String, dynamic>{
      'name': _name.text.trim(),
      'breed': _breed,
      'age': _age,
      'size': _size,
      'gender': _gender,
      'behaviour': _behaviour.toList(),
      'specialCare': _specialCare.toList(),
      // Retain the field for compatibility with older saved dog records.
      'notes': '',
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
        borderSide: const BorderSide(
          color: Color(0xFFE7E7E7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE7E7E7),
        ),
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

  Widget _label(String value, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        required ? '$value *' : value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: dogDetailsText,
        ),
      ),
    );
  }

  Widget _multiSelectSection({
    required String title,
    required String subtitle,
    required List<String> options,
    required Set<String> selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);

            return FilterChip(
              label: Text(option),
              selected: isSelected,
              showCheckmark: true,
              selectedColor: const Color(0xFFFFE5D1),
              checkmarkColor: dogDetailsOrange,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? dogDetailsText
                    : Colors.black87,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? dogDetailsOrange
                    : const Color(0xFFE7E7E7),
              ),
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

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
                  'Save your dog’s details once for future bookings.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                _label('Dog name', required: true),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  decoration: _decoration('e.g. Bruno'),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) {
                      return 'Enter your dog’s name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _label('Breed', required: true),
                DropdownButtonFormField<String>(
                  initialValue: _breed,
                  isExpanded: true,
                  decoration: _decoration('Choose breed'),
                  items: _dogBreeds.map((breed) {
                    return DropdownMenuItem(
                      value: breed,
                      child: Text(breed),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _breed = value);
                  },
                ),
                const SizedBox(height: 16),

                _label('Age', required: true),
                DropdownButtonFormField<String>(
                  initialValue: _age,
                  isExpanded: true,
                  decoration: _decoration('Choose age'),
                  items: _dogAges.map((age) {
                    return DropdownMenuItem(
                      value: age,
                      child: Text(age),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _age = value);
                  },
                ),
                const SizedBox(height: 16),

                _label('Dog size', required: true),
                DropdownButtonFormField<String>(
                  initialValue: _size,
                  isExpanded: true,
                  decoration: _decoration('Choose size'),
                  items: _dogSizes.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(size),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _size = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                _label('Gender'),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  isExpanded: true,
                  decoration: _decoration('Choose gender'),
                  items: _dogGenders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(
                        gender == 'Not specified'
                            ? 'Prefer not to specify'
                            : gender,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gender = value);
                    }
                  },
                ),
                const SizedBox(height: 20),

                _multiSelectSection(
                  title: 'Behaviour',
                  subtitle:
                      'Select all that describe your dog. '
                      'You can choose more than one.',
                  options: _dogBehaviours,
                  selected: _behaviour,
                ),
                const SizedBox(height: 20),

                _multiSelectSection(
                  title: 'Special care',
                  subtitle:
                      'Choose any care needs the walker should know.',
                  options: _dogCareOptions,
                  selected: _specialCare,
                ),
                const SizedBox(height: 22),

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
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
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
