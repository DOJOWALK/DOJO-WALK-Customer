
import 'package:flutter/material.dart';

import '../models/saved_address.dart';
import '../services/address_service.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.address});

  final SavedAddress? address;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const orange = Color(0xFFFF7900);
  static const background = Color(0xFFFFFAF5);

  final _formKey = GlobalKey<FormState>();
  final _flatController = TextEditingController();
  final _buildingController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _label = 'Home';
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final address = widget.address;
    if (address != null) {
      _label = address.label;
      _flatController.text = address.flatHouse;
      _buildingController.text = address.buildingSociety;
      _areaController.text = address.area;
      _landmarkController.text = address.landmark;
      _cityController.text = address.city;
      _pincodeController.text = address.pincode;
      _instructionsController.text = address.pickupInstructions;
      _isDefault = address.isDefault;
    }
  }

  @override
  void dispose() {
    _flatController.dispose();
    _buildingController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.address != null;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          editing ? 'Edit Address' : 'Add Address',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF202020),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          children: [
            const Text(
              'Where should the walker pick up your dog?',
              style: TextStyle(
                fontSize: 19,
                height: 1.3,
                fontWeight: FontWeight.w900,
                color: Color(0xFF202020),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Enter the correct pickup address so your walker can find you.',
              style: TextStyle(
                color: Color(0xFF777777),
                height: 1.5,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'SAVE ADDRESS AS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              children: ['Home', 'Work', 'Other'].map((label) {
                final selected = _label == label;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _label = label),
                  selectedColor: const Color(0xFFFFE5CF),
                  checkmarkColor: orange,
                  labelStyle: TextStyle(
                    color: selected ? orange : const Color(0xFF555555),
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(
                    color: selected ? orange : const Color(0xFFE5E5E5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            _field(
              controller: _flatController,
              label: 'Flat / House Number',
              hint: 'e.g. Flat 302, House 18',
              requiredField: true,
            ),
            _field(
              controller: _buildingController,
              label: 'Building / Society',
              hint: 'e.g. Tower B, ABC Society',
            ),
            _field(
              controller: _areaController,
              label: 'Area / Sector',
              hint: 'e.g. Sector 4, Gaur City',
              requiredField: true,
            ),
            _field(
              controller: _landmarkController,
              label: 'Landmark',
              hint: 'e.g. Near the main gate',
            ),
            _field(
              controller: _cityController,
              label: 'City',
              hint: 'Enter city',
              requiredField: true,
            ),
            _field(
              controller: _pincodeController,
              label: 'PIN Code',
              hint: '6-digit PIN Code',
              requiredField: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) {
                final pin = value?.trim() ?? '';
                if (!RegExp(r'^[0-9]{6}$').hasMatch(pin)) {
                  return 'Enter a valid 6-digit PIN Code';
                }
                return null;
              },
            ),
            _field(
              controller: _instructionsController,
              label: 'Pickup Instructions',
              hint: 'Gate, floor, entry instructions (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              activeColor: orange,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Set as default address',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Use this address as your preferred pickup location.',
                style: TextStyle(fontSize: 12, color: Color(0xFF777777)),
              ),
              onChanged: (value) {
                setState(() => _isDefault = value ?? false);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        editing ? 'Update Address' : 'Save Address',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.streetAddress,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (requiredField ? ' *' : ''),
            style: const TextStyle(
              color: Color(0xFF303030),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator ??
                (requiredField
                    ? (value) => value == null || value.trim().isEmpty
                        ? 'This field is required'
                        : null
                    : null),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: orange, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final old = widget.address;

      final address = SavedAddress(
        id: old?.id ?? '',
        label: _label,
        flatHouse: _flatController.text.trim(),
        buildingSociety: _buildingController.text.trim(),
        area: _areaController.text.trim(),
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        pickupInstructions: _instructionsController.text.trim(),
        latitude: old?.latitude,
        longitude: old?.longitude,
        isDefault: _isDefault,
      );

      await AddressService().saveAddress(
        address,
        makeDefault: _isDefault,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            old == null ? 'Address saved.' : 'Address updated.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save address. Please sign in and try again. ($error)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
