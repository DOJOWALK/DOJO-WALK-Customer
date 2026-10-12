
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/saved_address.dart';
import '../services/address_service.dart';

const Color addressOrange = Color(0xFFFF7900);
const Color addressBackground = Color(0xFFFFFAF5);

class AddressFormScreen extends StatefulWidget {
  final SavedAddress? address;

  const AddressFormScreen({
    super.key,
    this.address,
  });

  @override
  State<AddressFormScreen> createState() =>
      _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _searchController = TextEditingController();
  final _flatHouseController = TextEditingController();
  final _buildingController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _instructionsController = TextEditingController();

  final AddressService _addressService = AddressService();

  GoogleMapController? _mapController;

  static const LatLng _initialLocation = LatLng(
    28.6139,
    77.2090,
  );

  LatLng _selectedLocation = _initialLocation;

  String _label = 'Home';

  bool _saving = false;
  bool _resolvingAddress = false;
  bool _locationConfirmed = false;
  bool _isDefault = false;
  bool _isMapReady = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _loadExistingAddress();
  }

  void _loadExistingAddress() {
    final address = widget.address;

    if (address == null) return;

    _label = address.label;
    _flatHouseController.text = address.flatHouse;
    _buildingController.text = address.buildingSociety;
    _areaController.text = address.area;
    _landmarkController.text = address.landmark;
    _cityController.text = address.city;
    _pincodeController.text = address.pincode;
    _instructionsController.text = address.pickupInstructions;
    _isDefault = address.isDefault;

    if (address.latitude != null &&
        address.longitude != null) {
      _selectedLocation = LatLng(
        address.latitude!,
        address.longitude!,
      );
      _locationConfirmed = true;
    }

    _searchController.text = [
      address.flatHouse,
      address.area,
      address.city,
      address.pincode,
    ].where((value) => value.trim().isNotEmpty).join(', ');
  }

  @override
  void dispose() {
    _mapController?.dispose();

    _searchController.dispose();
    _flatHouseController.dispose();
    _buildingController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _instructionsController.dispose();

    super.dispose();
  }

  void _showMessage(String message) {
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

  Future<void> _moveMapTo(LatLng target) async {
    if (!mounted) return;

    setState(() {
      _selectedLocation = target;
      _locationConfirmed = true;
    });

    final controller = _mapController;

    if (controller != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 17,
          ),
        ),
      );
    }

    await _resolveAddress(target);
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _showMessage('Search for an address or area first.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _resolvingAddress = true);

    try {
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        _showMessage('Address location was not found.');
        return;
      }

      final result = locations.first;

      await _moveMapTo(
        LatLng(result.latitude, result.longitude),
      );
    } catch (_) {
      _showMessage(
        'Address search failed. Please try another address.',
      );
    } finally {
      if (mounted) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _resolvingAddress = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage('Please turn on your phone location.');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission is required.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Enable location permission in phone settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _moveMapTo(
        LatLng(position.latitude, position.longitude),
      );
    } catch (_) {
      _showMessage(
        'Unable to get your location. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  Future<void> _resolveAddress(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (!mounted || placemarks.isEmpty) return;

      final place = placemarks.first;

      final areaParts = [
        place.subLocality,
        place.thoroughfare,
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();

      final cityCandidates = [
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      final area = areaParts.join(', ');
      final city = cityCandidates.isNotEmpty
          ? cityCandidates.first
          : '';
      final pincode = place.postalCode?.trim() ?? '';

      setState(() {
        if (area.isNotEmpty) {
          _areaController.text = area;
        }

        if (city.isNotEmpty) {
          _cityController.text = city;
        }

        if (pincode.isNotEmpty) {
          _pincodeController.text = pincode;
        }

        _searchController.text = [
          area,
          city,
          pincode,
        ].where((value) => value.isNotEmpty).join(', ');
      });
    } catch (_) {
      // Address fields remain editable if geocoding fails.
    }
  }

  String? _requiredValidator(
    String? value,
    String message,
  ) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _pincodeValidator(String? value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')) {
      return 'Enter a valid 6-digit PIN code.';
    }

    return null;
  }

  Future<void> _saveAddress() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_locationConfirmed) {
      _showMessage(
        'Search an address, use current location, or move the map.',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final address = SavedAddress(
        id: widget.address?.id ?? '',
        label: _label,
        flatHouse: _flatHouseController.text.trim(),
        buildingSociety: _buildingController.text.trim(),
        area: _areaController.text.trim(),
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        pickupInstructions:
            _instructionsController.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt,
        updatedAt: widget.address?.updatedAt,
      );

      await _addressService.saveAddress(
        address,
        makeDefault: _isDefault,
      );

      if (!mounted) return;

      // Returns true so the previous screen can refresh its address list.
      Navigator.of(context).pop(true);
    } catch (error) {
      _showMessage(
        'Address could not be saved. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE7E0D9),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: addressOrange,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label, IconData icon) {
    final selected = _label == label;

    return ChoiceChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : addressOrange,
      ),
      selected: selected,
      selectedColor: addressOrange,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        setState(() => _label = label);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: addressBackground,
      appBar: AppBar(
        backgroundColor: addressBackground,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Address' : 'Add New Address',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Pickup Address',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Search your address or move the map to '
                      'choose the pickup point.',
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchAddress(),
                            decoration: InputDecoration(
                              hintText: 'Search address or area',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: addressOrange,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _resolvingAddress
                              ? null
                              : _searchAddress,
                          style: IconButton.styleFrom(
                            backgroundColor: addressOrange,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _selectedLocation,
                                zoom: 15,
                              ),
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _isMapReady = true;
                              },
                              onCameraMove: (position) {
                                _selectedLocation = position.target;
                                _locationConfirmed = true;
                              },
                              onCameraIdle: () {
                                _resolveAddress(_selectedLocation);
                              },
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              compassEnabled: true,
                            ),
                            const IgnorePointer(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 30),
                                child: Icon(
                                  Icons.location_pin,
                                  size: 46,
                                  color: addressOrange,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: FloatingActionButton.small(
                                heroTag: 'addressCurrentLocation',
                                backgroundColor: Colors.white,
                                foregroundColor: addressOrange,
                                onPressed: _resolvingAddress
                                    ? null
                                    : _getCurrentLocation,
                                child: const Icon(Icons.my_location),
                              ),
                            ),
                            if (_resolvingAddress)
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: addressOrange,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text('Finding address...'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(
                          _locationConfirmed
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 18,
                          color: _locationConfirmed
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _locationConfirmed
                                ? 'Pickup location selected'
                                : 'Select your pickup location',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      label: 'Flat / House Number',
                      controller: _flatHouseController,
                      hint: 'e.g. Flat 201, House 12',
                      required: true,
                      validator: (value) => _requiredValidator(
                        value,
                        'Enter your flat or house number.',
                      ),
                    ),

                    _buildTextField(
                      label: 'Building / Society',
                      controller: _buildingController,
                      hint: 'e.g. ABC Residency',
                    ),

                    _buildTextField(
                      label: 'Area / Locality',
                      controller: _areaController,
                      hint: 'Enter area or locality',
                      required: true,
                      validator: (value) => _requiredValidator(
                        value,
                        'Enter your area or locality.',
                      ),
                    ),

                    _buildTextField(
                      label: 'Landmark',
                      controller: _landmarkController,
                      hint: 'Nearby landmark (optional)',
                    ),

                    _buildTextField(
                      label: 'City',
                      controller: _cityController,
                      hint: 'Enter city',
                      required: true,
                      validator: (value) => _requiredValidator(
                        value,
                        'Enter your city.',
                      ),
                    ),

                    _buildTextField(
                      label: 'PIN Code',
                      controller: _pincodeController,
                      hint: '6-digit PIN code',
                      keyboardType: TextInputType.number,
                      required: true,
                      validator: _pincodeValidator,
                    ),

                    _buildTextField(
                      label: 'Pickup Instructions',
                      controller: _instructionsController,
                      hint: 'e.g. Call when you reach the gate',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Save Address As',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      children: [
                        _buildLabelChip('Home', Icons.home),
                        _buildLabelChip('Work', Icons.work),
                        _buildLabelChip('Other', Icons.location_on),
                      ],
                    ),

                    const SizedBox(height: 18),

                    CheckboxListTile(
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() => _isDefault = value ?? false);
                      },
                      activeColor: addressOrange,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Set as default address',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: addressOrange,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Check the pickup point before saving. '
                              'Its coordinates will be stored with '
                              'the address.',
                              style: TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: addressOrange,
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing
                                ? 'Update Address'
                                : 'Save Address',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
