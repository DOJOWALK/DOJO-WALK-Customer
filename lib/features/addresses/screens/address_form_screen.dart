
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/locale_controller.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/saved_address.dart';
import '../services/address_service.dart';

const Color addressOrange = DojoWalkTheme.primary;
const Color addressBackground = DojoWalkTheme.background;

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

  late LatLng _selectedLocation;

  String _label = 'Home';

  bool _saving = false;
  bool _resolvingAddress = false;
  bool _locationConfirmed = false;
  bool _isDefault = false;
  bool _mapMovementStarted = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_onLocaleChanged);
    _selectedLocation = _initialLocation;
    _loadExistingAddress();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  String _text(String en, String hi, String bn) =>
      appText(en: en, hi: hi, bn: bn);

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
    appLocale.removeListener(_onLocaleChanged);
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

    try {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17),
        ),
      );
    } catch (_) {
      // Keep the selected coordinates if camera animation fails.
    }

    await _resolveAddress(target);
  }

  Future<void> _searchAddress() async {
    if (_saving || _resolvingAddress) return;

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showMessage(_text('Enter an address or area first.', 'पहले पता या क्षेत्र लिखें।', 'প্রথমে ঠিকানা বা এলাকা লিখুন।'));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _resolvingAddress = true);

    try {
      final locations = await locationFromAddress(query);

      if (!mounted) return;

      if (locations.isEmpty) {
        _showMessage(_text('Could not find this address location.', 'इस पते की लोकेशन नहीं मिली।', 'এই ঠিকানার অবস্থান পাওয়া যায়নি।'));
        return;
      }

      final result = locations.first;
      await _moveMapTo(
        LatLng(result.latitude, result.longitude),
      );
    } catch (_) {
      _showMessage(
        _text(
          'Address search failed. Try another address.',
          'पता खोजा नहीं जा सका। दूसरा पता लिखकर कोशिश करें।',
          'ঠিকানা খোঁজা যায়নি। অন্য ঠিকানা দিয়ে চেষ্টা করুন।',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_resolvingAddress || _saving) return;

    setState(() => _resolvingAddress = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(_text('Turn on your phone location service.', 'फोन की लोकेशन चालू करें।', 'ফোনের লোকেশন চালু করুন।'));
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(_text('Location permission is required.', 'लोकेशन की अनुमति ज़रूरी है।', 'লোকেশনের অনুমতি প্রয়োজন।'));
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          _text(
            'Enable location permission in phone settings.',
            'फोन की सेटिंग्स में जाकर लोकेशन की अनुमति चालू करें।',
            'ফোনের সেটিংসে গিয়ে লোকেশনের অনুমতি চালু করুন।',
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      await _moveMapTo(
        LatLng(position.latitude, position.longitude),
      );
    } catch (_) {
      _showMessage(
        _text(
          'Could not get current location. Please try again.',
          'वर्तमान लोकेशन नहीं मिली। दोबारा कोशिश करें।',
          'বর্তমান অবস্থান পাওয়া যায়নি। আবার চেষ্টা করুন।',
        ),
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
      final city =
          cityCandidates.isNotEmpty ? cityCandidates.first : '';
      final pincode = place.postalCode?.trim() ?? '';

      setState(() {
        if (area.isNotEmpty) _areaController.text = area;
        if (city.isNotEmpty) _cityController.text = city;
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
      // Customer can enter address details manually.
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
      return _text('Enter a valid 6-digit PIN code.', 'सही 6 अंकों का PIN कोड लिखें।', 'সঠিক ৬ সংখ্যার PIN কোড লিখুন।');
    }
    return null;
  }

  Future<void> _saveAddress() async {
    if (_saving || _resolvingAddress) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_locationConfirmed) {
      _showMessage(
        _text(
          'Choose a pickup point using search, current location, or the map first.',
          'पहले सर्च, वर्तमान लोकेशन या मैप से पिकअप पॉइंट चुनें।',
          'প্রথমে সার্চ, বর্তমান অবস্থান বা মানচিত্র থেকে পিকআপের স্থান বেছে নিন।',
        ),
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
        pickupInstructions: _instructionsController.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt,
        updatedAt: widget.address?.updatedAt,
      );

      final savedAddressId = await _addressService.saveAddress(
        address,
        makeDefault: _isDefault,
      );

      if (!mounted) return;
      Navigator.of(context).pop(savedAddressId);
    } catch (_) {
      _showMessage(
        _text(
          'Address could not be saved. Check your internet and try again.',
          'पता सेव नहीं हुआ। इंटरनेट जाँचकर दोबारा कोशिश करें।',
          'ঠিকানা সংরক্ষণ করা যায়নি। ইন্টারনেট পরীক্ষা করে আবার চেষ্টা করুন।',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
      padding: const EdgeInsets.only(bottom: 14),
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
          fillColor: addressBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE7E0D9),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFE7E0D9),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
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
      onSelected: _saving
          ? null
          : (_) => setState(() => _label = label),
    );
  }

  Widget _buildAddressSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.57,
      minChildSize: 0.22,
      maxChildSize: 0.90,
      snap: true,
      snapSizes: const [0.57, 0.90],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D3CE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E3),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: addressOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? _text('Edit Pickup Address', 'पिकअप पता बदलें', 'পিকআপের ঠিকানা সম্পাদনা করুন')
                                : _text('Address Details', 'पते का विवरण', 'ঠিকানার বিবরণ'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _locationConfirmed
                                ? _text('Pickup point selected', 'पिकअप पॉइंट चुना गया', 'পিকআপের স্থান বেছে নেওয়া হয়েছে')
                                : _text('Choose the correct pickup point on the map', 'मैप पर सही पिकअप पॉइंट चुनें', 'মানচিত্রে সঠিক পিকআপের স্থান বেছে নিন'),
                            style: TextStyle(
                              fontSize: 12,
                              color: _locationConfirmed
                                  ? Colors.green.shade700
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _buildTextField(
                  label: _text('Flat / House Number', 'फ्लैट / मकान नंबर', 'ফ্ল্যাট / বাড়ির নম্বর'),
                  controller: _flatHouseController,
                  hint: _text('e.g. Flat 201, House 12', 'जैसे फ्लैट 201, मकान 12', 'যেমন ফ্ল্যাট ২০১, বাড়ি ১২'),
                  required: true,
                  validator: (value) => _requiredValidator(
                    value,
                    _text('Enter your flat or house number.', 'फ्लैट या मकान नंबर लिखें।', 'ফ্ল্যাট বা বাড়ির নম্বর লিখুন।'),
                  ),
                ),
                _buildTextField(
                  label: _text('Building / Society', 'बिल्डिंग / सोसाइटी', 'বিল্ডিং / সোসাইটি'),
                  controller: _buildingController,
                  hint: _text('e.g. ABC Residency', 'जैसे ABC Residency', 'যেমন ABC Residency'),
                ),
                _buildTextField(
                  label: _text('Area / Locality', 'क्षेत्र / इलाका', 'এলাকা / পাড়া'),
                  controller: _areaController,
                  hint: _text('Enter area or locality', 'क्षेत्र या इलाका लिखें', 'এলাকা বা পাড়া লিখুন'),
                  required: true,
                  validator: (value) => _requiredValidator(
                    value,
                    _text('Enter your area or locality.', 'अपना क्षेत्र या इलाका लिखें।', 'আপনার এলাকা বা পাড়া লিখুন।'),
                  ),
                ),
                _buildTextField(
                  label: _text('Landmark', 'नज़दीकी पहचान', 'কাছাকাছি পরিচিত স্থান'),
                  controller: _landmarkController,
                  hint: _text('Nearby landmark (optional)', 'पास की पहचान (वैकल्पिक)', 'কাছাকাছি পরিচিত স্থান (ঐচ্ছিক)'),
                ),
                _buildTextField(
                  label: _text('City', 'शहर', 'শহর'),
                  controller: _cityController,
                  hint: _text('Enter city', 'शहर लिखें', 'শহরের নাম লিখুন'),
                  required: true,
                  validator: (value) => _requiredValidator(
                    value,
                    _text('Enter your city.', 'अपना शहर लिखें।', 'আপনার শহরের নাম লিখুন।'),
                  ),
                ),
                _buildTextField(
                  label: _text('PIN Code', 'पिन कोड', 'পিন কোড'),
                  controller: _pincodeController,
                  hint: _text('6-digit PIN code', '6 अंकों का पिन कोड', '৬ সংখ্যার পিন কোড'),
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: _pincodeValidator,
                ),
                _buildTextField(
                  label: _text('Pickup Instructions', 'पिकअप के निर्देश', 'পিকআপের নির্দেশনা'),
                  controller: _instructionsController,
                  hint: _text('e.g. Call when you reach the gate', 'जैसे गेट पर पहुँचकर कॉल करें', 'যেমন গেটে পৌঁছে ফোন করুন'),
                  maxLines: 3,
                ),

                Text(
                  _text('Save Address As', 'पता इस नाम से सेव करें', 'এই নামে ঠিকানা সংরক্ষণ করুন'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildLabelChip('Home', Icons.home),
                    _buildLabelChip('Work', Icons.work),
                    _buildLabelChip('Other', Icons.location_on),
                  ],
                ),

                const SizedBox(height: 12),

                CheckboxListTile(
                  value: _isDefault,
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                            () => _isDefault = value ?? false,
                          ),
                  activeColor: addressOrange,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _text('Set as default address', 'डिफ़ॉल्ट पता बनाएँ', 'ডিফল্ট ঠিকানা হিসেবে রাখুন'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 10),

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
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _text('Check the pickup point on the map before saving. The map coordinates will be saved with the address.', 'सेव करने से पहले मैप पर पिकअप पॉइंट जाँचें। मैप के निर्देशांक पते के साथ सेव होंगे।', 'সংরক্ষণের আগে মানচিত্রে পিকআপের স্থান পরীক্ষা করুন। মানচিত্রের স্থানাঙ্ক ঠিকানার সঙ্গে সংরক্ষিত হবে।'),
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving || _resolvingAddress
                        ? null
                        : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: addressOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing
                                ? _text('Update Address', 'पता अपडेट करें', 'ঠিকানা আপডেট করুন')
                                : _text('Save Address', 'पता सेव करें', 'ঠিকানা সংরক্ষণ করুন'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: addressBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMoveStarted: () {
                _mapMovementStarted = true;
              },
              onCameraMove: (position) {
                _selectedLocation = position.target;
              },
              onCameraIdle: () {
                if (_mapMovementStarted && mounted) {
                  setState(() => _locationConfirmed = true);
                  _resolveAddress(_selectedLocation);
                }
                _mapMovementStarted = false;
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
            ),
          ),

          // Fixed pickup pin in the centre of the map.
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: Icon(
                    Icons.location_pin,
                    size: 48,
                    color: addressOrange,
                  ),
                ),
              ),
            ),
          ),

          // Top search bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.black87,
                            tooltip: _text('Back', 'वापस', 'ফিরে যান'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchAddress(),
                              decoration: InputDecoration(
                                hintText: _text('Search address or area', 'पता या क्षेत्र खोजें', 'ঠিকানা বা এলাকা খুঁজুন'),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: addressOrange,
                                ),
                                suffixIcon: IconButton(
                                  onPressed:
                                      _resolvingAddress || _saving
                                          ? null
                                          : _searchAddress,
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: addressOrange,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_resolvingAddress) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        color: addressOrange,
                        minHeight: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Current-location button above the sheet.
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.59,
            child: SafeArea(
              child: Material(
                color: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: _resolvingAddress || _saving
                      ? null
                      : _getCurrentLocation,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: addressOrange,
                  ),
                  tooltip: _text('Use current location', 'वर्तमान लोकेशन इस्तेमाल करें', 'বর্তমান অবস্থান ব্যবহার করুন'),
                ),
              ),
            ),
          ),

          _buildAddressSheet(),
        ],
      ),
    );
  }
}
