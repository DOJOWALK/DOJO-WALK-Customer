
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../profile/screens/my_dogs_screen.dart';
import '../../addresses/models/saved_address.dart';
import '../../addresses/services/address_service.dart';
import '../../addresses/screens/address_form_screen.dart';

import 'booking_confirmation_screen.dart';

const Color detailsOrange = Color(0xFFFF7900);
const Color detailsBackground = Color(0xFFFFFAF5);
const Color detailsText = Color(0xFF202020);

class DogPickupDetailsScreen extends StatefulWidget {
  const DogPickupDetailsScreen({
    super.key,
    required this.walkType,
    required this.schedule,
  });

  final WalkBookingType walkType;
  final Map<String, dynamic> schedule;

  @override
  State<DogPickupDetailsScreen> createState() =>
      _DogPickupDetailsScreenState();
}

class _DogPickupDetailsScreenState
    extends State<DogPickupDetailsScreen> {
  String? selectedDogId;
  Map<String, dynamic>? selectedDog;
  SavedAddress? selectedAddress;
  bool continuing = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _pets(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets');
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      backgroundColor: detailsBackground,
      appBar: AppBar(
        backgroundColor: detailsBackground,
        foregroundColor: detailsText,
        elevation: 0,
        title: const Text(
          'Dog & Pickup Details',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: user == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Please sign in to choose your dog and pickup address.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'Your walk, your way',
                  style: TextStyle(
                    color: detailsText,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select the dog and pickup location for this booking.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                _sectionTitle(
                  '1. Choose Your Dog',
                  Icons.pets_rounded,
                  'Add Dog',
                  _openMyDogs,
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _pets(user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _notice(
                        'Unable to load dogs. Please check your connection '
                        'and Firestore permissions.',
                      );
                    }

                    if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: detailsOrange,
                          ),
                        ),
                      );
                    }

                    final dogs = snapshot.data?.docs ?? [];

                    if (dogs.isEmpty) {
                      return _notice(
                        'No saved dogs found. Tap Add Dog to add a dog.',
                      );
                    }

                    return Column(
                      children: dogs.map((doc) {
                        final dog = doc.data();
                        final isSelected = selectedDogId == doc.id;

                        final details = [
                          dog['breed'],
                          dog['age'],
                          dog['size'],
                          dog['gender'],
                        ]
                            .where((value) =>
                                value != null &&
                                value.toString().trim().isNotEmpty)
                            .join(' • ');

                        return _selectCard(
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedDogId = doc.id;
                              selectedDog = {
                                ...dog,
                                'dogId': doc.id,
                              };
                            });
                          },
                          child: Row(
                            children: [
                              _iconBox(Icons.pets_rounded),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (dog['name'] ?? 'My Dog').toString(),
                                      style: const TextStyle(
                                        color: detailsText,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (details.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        details,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? detailsOrange
                                    : Colors.black38,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 26),

                _sectionTitle(
                  '2. Pickup Address',
                  Icons.location_on_rounded,
                  'Add Address',
                  _addAddress,
                ),
                const SizedBox(height: 10),

                StreamBuilder<List<SavedAddress>>(
                  stream: AddressService().watchAddresses(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _notice(
                        'Unable to load addresses. Please try again.',
                      );
                    }

                    if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: detailsOrange,
                          ),
                        ),
                      );
                    }

                    final addresses = snapshot.data ?? [];

                    if (addresses.isEmpty) {
                      return _notice(
                        'No saved addresses found. Add a pickup address '
                        'before continuing.',
                      );
                    }

                    final selectedStillExists = selectedAddress != null &&
                        addresses.any(
                          (address) => address.id == selectedAddress!.id,
                        );

                    if (selectedAddress == null || !selectedStillExists) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;

                        final currentStillExists =
                            selectedAddress != null &&
                                addresses.any(
                                  (address) =>
                                      address.id == selectedAddress!.id,
                                );

                        if (currentStillExists) return;

                        final defaults =
                            addresses.where((a) => a.isDefault).toList();

                        setState(() {
                          selectedAddress = defaults.isNotEmpty
                              ? defaults.first
                              : addresses.first;
                        });
                      });
                    }

                    return Column(
                      children: addresses.map((address) {
                        final isSelected =
                            selectedAddress?.id == address.id;

                        final fullAddress = [
                          address.flatHouse,
                          address.buildingSociety,
                          address.area,
                          address.landmark,
                          address.city,
                          address.pincode,
                        ]
                            .where((value) => value.trim().isNotEmpty)
                            .join(', ');

                        return _selectCard(
                          selected: isSelected,
                          onTap: () {
                            setState(() => selectedAddress = address);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _iconBox(Icons.location_on_rounded),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            address.label,
                                            style: const TextStyle(
                                              color: detailsText,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        if (address.isDefault)
                                          const Text(
                                            'DEFAULT',
                                            style: TextStyle(
                                              color: detailsOrange,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      fullAddress.isEmpty
                                          ? 'Address details unavailable'
                                          : fullAddress,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        height: 1.5,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (address.pickupInstructions
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Instructions: '
                                        '${address.pickupInstructions}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? detailsOrange
                                    : Colors.black38,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAD8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: detailsOrange,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please confirm that the selected dog and pickup '
                          'address are correct before continuing.',
                          style: TextStyle(
                            color: detailsText,
                            fontSize: 12,
                            height: 1.5,
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
                    onPressed: continuing ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: detailsOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: continuing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Confirmation',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
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
    );
  }

  Future<void> _openMyDogs() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MyDogsScreen(),
      ),
    );

    // The Firestore stream updates when the user returns.
  }

  Future<void> _addAddress() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddressFormScreen(),
      ),
    );

    // AddressService stream refreshes the saved address list.
  }

  Future<void> _continue() async {
    if (continuing) return;

    if (selectedDogId == null || selectedDog == null) {
      _showMessage('Please select your dog.');
      return;
    }

    if (selectedAddress == null) {
      _showMessage('Please select a pickup address.');
      return;
    }

    final address = selectedAddress!;

    final addressMap = <String, dynamic>{
      'addressId': address.id,
      'label': address.label,
      'flatHouse': address.flatHouse,
      'buildingSociety': address.buildingSociety,
      'address': [
        address.flatHouse,
        address.buildingSociety,
      ].where((value) => value.trim().isNotEmpty).join(', '),
      'area': address.area,
      'landmark': address.landmark,
      'city': address.city,
      'pincode': address.pincode,
      'pickupInstructions': address.pickupInstructions,
      'isDefault': address.isDefault,
    };

    setState(() => continuing = true);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookingConfirmationScreen(
            walkType: widget.walkType,
            dogDetails: {
              ...selectedDog!,
              'dogId': selectedDogId,
            },
            pickupAddress: addressMap,
            schedule: widget.schedule,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Could not open confirmation: $error');
      }
    } finally {
      if (mounted) {
        setState(() => continuing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Row(
      children: [
        Icon(icon, color: detailsOrange, size: 23),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: detailsText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: detailsOrange,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _selectCard({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? detailsOrange : const Color(0xFFEAEAEA),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: detailsOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: detailsOrange,
        size: 25,
      ),
    );
  }

  Widget _notice(String message) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }
}
