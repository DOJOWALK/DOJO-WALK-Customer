
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final _searchController = TextEditingController();
  final _flatController = TextEditingController();
  final _buildingController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _instructionsController = TextEditingController();

  GoogleMapController? _mapController;

  // Initial camera only. These are not saved as a confirmed pickup
  // location until the map pin coordinates have been selected.
  static const LatLng _initialCamera = LatLng(28.47, 77.50);

  late LatLng _selectedPosition;
  LatLng? _pendingPosition;

  String _label = 'Home';
  bool _isDefault = false;
  bool _saving = false;
  bool _resolvingAddress = false;
  bool _locationConfirmed = false;
  bool _mapReady = false;

  Timer? _searchDebounce;
  int _lookupVersion = 0;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();

    final old = widget.address;

    _selectedPosition = old?.latitude != null &&
            old?.longitude != null
        ? LatLng(old!.latitude!, old.longitude!)
        : _initialCamera;

    if (old != null) {
      _label = old.label;
      _flatController.text = old.flatHouse;
      _buildingController.text = old.buildingSociety;
      _areaController.text = old.area;
      _cityController.text = old.city;
      _pincodeController.text = old.pincode;
      _landmarkController.text = old.landmark;
      _instructionsController.text = old.pickupInstructions;

      _locationConfirmed =
          old.latitude != null && old.longitude != null;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _flatController.dispose();
    _buildingController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _pendingPosition = position.target;
  }

  Future<void> _onCameraIdle() async {
    final position = _pendingPosition;
    if (position == null || !mounted) return;

    _selectedPosition = position;
    _locationConfirmed = true;

    await _fillAddressFromCoordinates(position);
  }

  Future<void> _fillAddressFromCoordinates(LatLng position) async {
    final version = ++_lookupVersion;

    if (mounted) {
      setState(() => _resolvingAddress = true);
    }

    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted || version != _lookupVersion) return;

      if (places.isNotEmpty) {
        final place = places.first;

        final area = [
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
        ].whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .join(', ');

        final city = [
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
        ].whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .firstOrNull;

        final pin = place.postalCode?.trim() ?? '';

        if (area.isNotEmpty) _areaController.text = area;
        if (city != null && city.isNotEmpty) {
          _cityController.text = city;
        }
        if (RegExp(r'^[0-9]{6}$').hasMatch(pin)) {
          _pincodeController.text = pin;
        }
      }
    } catch (_) {
      // Manual address entry remains available if reverse geocoding
      // is unavailable or cannot find an address.
    } finally {
      if (mounted && version == _lookupVersion) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _message('पहले जगह या address लिखें।');
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      final results = await locationFromAddress(query);

      if (results.isEmpty) {
        _message('यह जगह नहीं मिली। दूसरा address खोजें।');
        return;
      }

      final result = results.first;
      final target = LatLng(result.latitude, result.longitude);

      _pendingPosition = target;
      _selectedPosition = target;
      _locationConfirmed = true;

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 17),
      );

      if (mounted) setState(() {});
      await _fillAddressFromCoordinates(target);
    } catch (_) {
      _message(
        'जगह खोज नहीं पाए। Map को move करके location चुनें।',
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _message('फोन की Location/GPS चालू करें।');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _message('Current Location के लिए location permission दें।');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _message(
          'Phone Settings में जाकर DOJO WALK की location permission चालू करें।',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final target = LatLng(
        position.latitude,
        position.longitude,
      );

      _pendingPosition = target;
      _selectedPosition = target;
      _locationConfirmed = true;

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 17),
      );

      if (mounted) setState(() {});
      await _fillAddressFromCoordinates(target);
    } catch (_) {
      _message(
        'Current Location नहीं मिल सकी। Search या Map से जगह चुनें।',
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_locationConfirmed ||
        !_selectedPosition.latitude.isFinite ||
        !_selectedPosition.longitude.isFinite ||
        _selectedPosition.latitude.abs() > 90 ||
        _selectedPosition.longitude.abs() > 180) {
      _message('पहले Map पर सही pickup location चुनें।');
      return;
    }

    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final old = widget.address;

    try {
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
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        isDefault: _isDefault,
      );

      await AddressService().saveAddress(
        address,
        makeDefault: _isDefault,
      );

      if (!mounted) return;

      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            old == null
                ? 'Address saved successfully.'
                : 'Address updated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _message(
        'Address save नहीं हुआ। Internet, login और Firebase permissions जाँचें।',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Map remains behind the address bottom sheet.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.62,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: _locationConfirmed ? 17 : 12,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _mapReady = true;
              },
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onTap: (point) {
                _pendingPosition = point;
                _selectedPosition = point;
                _locationConfirmed = true;

                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(point),
                );

                setState(() {});
              },
            ),
          ),

          // Top search and navigation.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchPlace(),
                            decoration: InputDecoration(
                              hintText: 'Search places or address',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: orange,
                              ),
                              suffixIcon: IconButton(
                                tooltip: 'Search',
                                onPressed: _searchPlace,
                                icon: const Icon(Icons.arrow_forward),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.white,
                      elevation: 3,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: _useCurrentLocation,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 11,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.my_location,
                                color: orange,
                                size: 20,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Current Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed center pin: moving the map selects another location.
          Positioned(
            top: size.height * 0.275,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 46,
                    color: orange,
                  ),
                  Container(
                    width: 7,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Address bottom sheet.
          Positioned(
            top: size.height * 0.405,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6D6D6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      _editing ? 'Edit Address' : 'Confirm your address',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF202020),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Location से address auto-fill होगा। सही पता जाँचकर भरें।',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF777777),
                        height: 1.4,
                      ),
                    ),
                    if (_resolvingAddress) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        color: orange,
                        minHeight: 2,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Address details खोज रहे हैं…',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'SAVE ADDRESS AS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF777777),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      children: ['Home', 'Work', 'Other'].map((label) {
                        final selected = _label == label;

                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _label = label);
                          },
                          selectedColor: const Color(0xFFFFE5CF),
                          checkmarkColor: orange,
                          side: BorderSide(
                            color: selected
                                ? orange
                                : const Color(0xFFE5E5E5),
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? orange
                                : const Color(0xFF555555),
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 17),
                    _field(
                      controller: _flatController,
                      label: 'House / Flat / Tower',
                      hint: 'House, flat या tower नंबर',
                      requiredField: true,
                    ),
                    _field(
                      controller: _buildingController,
                      label: 'Building / Society',
                      hint: 'Building या society का नाम (optional)',
                    ),
                    _field(
                      controller: _areaController,
                      label: 'Area / Society',
                      hint: 'Area या society का नाम',
                      requiredField: true,
                    ),
                    _field(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
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
                        if (!RegExp(r'^[0-9]{6}$')
                            .hasMatch(value?.trim() ?? '')) {
                          return 'सही 6-digit PIN Code भरें';
                        }
                        return null;
                      },
                    ),
                    _field(
                      controller: _landmarkController,
                      label: 'Landmark',
                      hint: 'पास की जगह या landmark (optional)',
                    ),
                    _field(
                      controller: _instructionsController,
                      label: 'Pickup Instructions',
                      hint: 'Gate, floor, entry details (optional)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xFFE8E8E8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: orange,
                            size: 25,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locationConfirmed
                                      ? 'Pickup pin selected'
                                      : 'Pickup location not confirmed',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _locationConfirmed
                                      ? '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}'
                                      : 'Search करें या Map से जगह चुनें',
                                  style: const TextStyle(
                                    color: Color(0xFF777777),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _locationConfirmed
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: _locationConfirmed
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
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
                      onChanged: (value) {
                        setState(() => _isDefault = value ?? false);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFFFC18E),
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
                                _editing
                                    ? 'Update Address'
                                    : 'Save Address',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 46,
          width: 46,
          child: Icon(icon, color: const Color(0xFF202020)),
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
      padding: const EdgeInsets.only(bottom: 15),
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
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator ??
                (requiredField
                    ? (value) =>
                        value == null || value.trim().isEmpty
                            ? 'यह field जरूरी है'
                            : null
                    : null),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide:
                    const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide:
                    const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide:
                    const BorderSide(color: orange, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
