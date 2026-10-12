import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../addresses/models/saved_address.dart';
import '../../addresses/services/address_service.dart';
import '../../addresses/screens/address_form_screen.dart';
import 'booking_start_screen.dart';
import 'walk_schedule_screen.dart';

const Color addressOrange = Color(0xFFFF7900);
const Color addressText = Color(0xFF202020);
const Color addressBackground = Color(0xFFFFFAF5);

class PickupAddressScreen extends StatefulWidget {
  const PickupAddressScreen({
    super.key,
    required this.walkType,
    required this.dogDetails,
  });

  final WalkBookingType walkType;
  final Map<String, dynamic> dogDetails;

  @override
  State<PickupAddressScreen> createState() =>
      _PickupAddressScreenState();
}

class _PickupAddressScreenState extends State<PickupAddressScreen> {
  final AddressService _addressService = AddressService();

  List<SavedAddress> _addresses = [];
  String? _selectedAddressId;

  bool _loading = true;
  bool _openingForm = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (!mounted) return;

      setState(() {
        _addresses = [];
        _selectedAddressId = null;
        _loading = false;
      });
      return;
    }

    try {
      final addresses = await _addressService.getAddresses();

      if (!mounted) return;

      final selectedStillExists = addresses.any(
        (address) => address.id == _selectedAddressId,
      );

      setState(() {
        _addresses = addresses;

        if (!selectedStillExists) {
          final defaultAddresses = addresses.where(
            (address) => address.isDefault,
          );

          _selectedAddressId = defaultAddresses.isNotEmpty
              ? defaultAddresses.first.id
              : null;
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(
        'Saved addresses लोड नहीं हुए। Internet और login जाँचें।',
      );
    }
  }

  Future<void> _addAddress() async {
    if (_openingForm) return;

    if (FirebaseAuth.instance.currentUser == null) {
      _showMessage('Address save करने के लिए पहले login करें।');
      return;
    }

    setState(() => _openingForm = true);

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const AddressFormScreen(),
        ),
      );

      if (!mounted) return;

      // AddressFormScreen saves the address and pops back.
      // Reload the list so the newly saved address appears.
      await _loadAddresses();

      if (!mounted) return;

      // If there is exactly one address, select it automatically.
      // If there are several, let the customer choose.
      if (_addresses.length == 1) {
        setState(() {
          _selectedAddressId = _addresses.first.id;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _openingForm = false);
      }
    }
  }

  void _continue() {
    SavedAddress? selected;

    for (final address in _addresses) {
      if (address.id == _selectedAddressId) {
        selected = address;
        break;
      }
    }

    if (selected == null) {
      _showMessage('आगे बढ़ने के लिए pickup address चुनें।');
      return;
    }

    if (selected.latitude == null || selected.longitude == null) {
      _showMessage(
        'इस address की map location उपलब्ध नहीं है। '
        'Address को edit करके location चुनें।',
      );
      return;
    }

    // Create a snapshot so later edits to the saved address
    // do not change the address details already passed to booking.
    final pickupAddress = <String, dynamic>{
      'addressId': selected.id,
      'label': selected.label,
      'address': selected.flatHouse,
      'flatHouse': selected.flatHouse,
      'buildingSociety': selected.buildingSociety,
      'area': selected.area,
      'landmark': selected.landmark,
      'city': selected.city,
      'pincode': selected.pincode,
      'pickupInstructions': selected.pickupInstructions,
      'latitude': selected.latitude,
      'longitude': selected.longitude,
    };

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalkScheduleScreen(
          walkType: widget.walkType,
          dogDetails: widget.dogDetails,
          pickupAddress: pickupAddress,
        ),
      ),
    );
  }

  void _showMessage(String message) {
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
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: addressBackground,
        appBar: AppBar(
          backgroundColor: addressBackground,
          title: const Text(
            'Pickup Address',
            style: TextStyle(
              color: addressText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Saved address देखने और booking जारी रखने के लिए login करें।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: addressBackground,
      appBar: AppBar(
        backgroundColor: addressBackground,
        elevation: 0,
        title: const Text(
          'Pickup Address',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: addressText,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: addressOrange,
                      ),
                    )
                  : RefreshIndicator(
                      color: addressOrange,
                      onRefresh: _loadAddresses,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          12,
                          18,
                          24,
                        ),
                        children: [
                          const Text(
                            'Where should we pick up your dog?',
                            style: TextStyle(
                              fontSize: 25,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              color: addressText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'अपना saved address चुनें या नया address जोड़ें।',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_addresses.isEmpty)
                            _emptyAddressCard()
                          else
                            ..._addresses.map(_addressCard),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed:
                                _openingForm ? null : _addAddress,
                            icon: _openingForm
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: addressOrange,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_location_alt_outlined,
                                  ),
                            label: const Text(
                              'Add New Address',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: addressOrange,
                              minimumSize: const Size.fromHeight(52),
                              side: const BorderSide(
                                color: addressOrange,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE)),
                ),
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: addressOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFFC18E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyAddressCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 46,
            color: addressOrange,
          ),
          SizedBox(height: 10),
          Text(
            'No saved addresses yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: addressText,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'पहले अपना pickup address जोड़ें। '
            'उसके बाद आप उसे अगली booking में दोबारा चुन सकते हैं।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(SavedAddress address) {
    final selected = _selectedAddressId == address.id;

    final icon = switch (address.label.toLowerCase()) {
      'home' => Icons.home_rounded,
      'work' => Icons.work_rounded,
      _ => Icons.location_on_rounded,
    };

    final details = [
      address.flatHouse,
      address.buildingSociety,
      address.area,
      address.landmark,
      address.city,
      address.pincode,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () {
            setState(() => _selectedAddressId = address.id);
          },
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? addressOrange
                    : const Color(0xFFE8E8E8),
                width: selected ? 1.7 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFE5CF)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? addressOrange : Colors.black54,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: addressText,
                              ),
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: addressOrange,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'Default',
                              style: TextStyle(
                                color: addressOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        details.isEmpty ? 'Address details missing' : details,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      if (address.pickupInstructions.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Instructions: ${address.pickupInstructions}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? addressOrange : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
