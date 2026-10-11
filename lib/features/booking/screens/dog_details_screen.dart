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
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  String _size = 'Medium';
  String _gender = 'Not specified';

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    final dogDetails = <String, dynamic>{
      'name': _nameController.text.trim(),
      'breed': _breedController.text.trim(),
      'age': _ageController.text.trim(),
      'size': _size,
      'gender': _gender,
      'notes': _notesController.text.trim(),
    };

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PickupAddressScreen(
          walkType: widget.walkType,
          dogDetails: dogDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walkTypeLabel =
        widget.walkType == WalkBookingType.regular
            ? 'Regular Walks'
            : 'One-Time Walk';

    return Scaffold(
      backgroundColor: dogDetailsBackground,
      appBar: AppBar(
        backgroundColor: dogDetailsBackground,
        elevation: 0,
        title: const Text(
          'Your Dog',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: dogDetailsText,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  _progressStep('1', 'Service', true),
                  _progressLine(),
                  _progressStep('2', 'Your Dog', true),
                  _progressLine(),
                  _progressStep('3', 'Address', false),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                walkTypeLabel,
                style: const TextStyle(
                  color: dogDetailsOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Tell us about your dog',
                style: TextStyle(
                  fontSize: 27,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  color: dogDetailsText,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'These details help your walker provide safe, '
                'comfortable and suitable care.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: dogDetailsOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: dogDetailsOrange,
                    size: 46,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _label('Dog’s name *'),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _decoration('e.g. Bruno'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your dog’s name';
                  }

                  if (value.trim().length > 50) {
                    return 'Name must be under 50 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              _label('Breed'),

              TextFormField(
                controller: _breedController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _decoration('e.g. Labrador or Indie'),
              ),

              const SizedBox(height: 18),

              _label('Age in years'),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
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

              const SizedBox(height: 18),

              _label('Dog size *'),

              DropdownButtonFormField<String>(
                initialValue: _size,
                isExpanded: true,
                decoration: _decoration('Select dog size'),
                items: const [
                  DropdownMenuItem(
                    value: 'Small',
                    child: Text('Small'),
                  ),
                  DropdownMenuItem(
                    value: 'Medium',
                    child: Text('Medium'),
                  ),
                  DropdownMenuItem(
                    value: 'Large',
                    child: Text('Large'),
                  ),
                  DropdownMenuItem(
                    value: 'Extra Large',
                    child: Text('Extra Large'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _size = value);
                  }
                },
              ),

              const SizedBox(height: 18),

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
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _gender = value);
                  }
                },
              ),

              const SizedBox(height: 18),

              _label('Special instructions (optional)'),

              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                maxLength: 300,
                decoration: _decoration(
                  'Behaviour, leash needs, fears or care instructions',
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: dogDetailsOrange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please share any important behaviour or '
                        'care information your walker should know.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dogDetailsOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
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
          ),
        ),
      ),
    );
  }

  Widget _progressStep(
    String number,
    String label,
    bool active,
  ) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? dogDetailsOrange : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? dogDetailsOrange
                  : const Color(0xFFDDDDDD),
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : Colors.black45,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? dogDetailsText : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _progressLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(
          left: 8,
          right: 8,
          bottom: 18,
        ),
        color: const Color(0xFFE8D5C5),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF303030),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE7E7E7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE7E7E7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: dogDetailsOrange,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}
