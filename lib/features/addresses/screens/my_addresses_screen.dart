
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/saved_address.dart';
import '../services/address_service.dart';
import 'address_form_screen.dart';

const Color addressOrange = Color(0xFFFF7900);
const Color addressBackground = Color(0xFFFFFAF5);
const Color addressText = Color(0xFF202020);
const Color addressMuted = Color(0xFF777777);

class MyAddressesScreen extends StatelessWidget {
  const MyAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: addressBackground,
        appBar: AppBar(title: const Text('Saved Addresses')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Please sign in to manage your saved addresses.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final service = AddressService();

    return Scaffold(
      backgroundColor: addressBackground,
      appBar: AppBar(
        backgroundColor: addressBackground,
        elevation: 0,
        title: const Text(
          'Saved Addresses',
          style: TextStyle(
            color: addressText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<List<SavedAddress>>(
        stream: service.watchAddresses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              'Could not load addresses.\nPlease check your connection and try again.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: addressOrange),
            );
          }

          final addresses = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAD8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_rounded, color: addressOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Save your pickup locations for faster dog-walk bookings.',
                        style: TextStyle(
                          color: addressText,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (addresses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.location_searching_rounded,
                        size: 48,
                        color: addressOrange,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No saved addresses yet',
                        style: TextStyle(
                          color: addressText,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Add your home or another pickup location.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: addressMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...addresses.map(
                  (address) => _addressCard(
                    context,
                    service,
                    address,
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: addressOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text(
              'Add New Address',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressCard(
    BuildContext context,
    AddressService service,
    SavedAddress address,
  ) {
    final details = [
      address.flatHouse,
      address.buildingSociety,
      address.area,
      address.landmark,
      address.city,
      address.pincode,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: address.isDefault
              ? addressOrange.withValues(alpha: 0.55)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  address.label == 'Home'
                      ? Icons.home_rounded
                      : address.label == 'Work'
                          ? Icons.work_outline_rounded
                          : Icons.location_on_outlined,
                  color: addressOrange,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  address.label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: addressText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAD8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(
                      color: addressOrange,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            details,
            style: const TextStyle(
              color: addressText,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          if (address.pickupInstructions.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              'Pickup instructions: ${address.pickupInstructions}',
              style: const TextStyle(
                color: addressMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const Divider(height: 25),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (!address.isDefault)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await service.setDefaultAddress(address.id);
                    } catch (_) {
                      if (context.mounted) {
                        _showMessage(context, 'Could not update default address.');
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Set Default'),
                ),
              TextButton.icon(
                onPressed: () => _openForm(context, address: address),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, service, address),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    SavedAddress? address,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddressFormScreen(address: address),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AddressService service,
    SavedAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete address?'),
        content: const Text(
          'This saved address will be removed from your account. '
          'Existing bookings will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Address'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await service.deleteAddress(address.id);
      if (context.mounted) {
        _showMessage(context, 'Address deleted.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Could not delete address. Please try again.');
      }
    }
  }

  Widget _message(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: addressMuted, height: 1.5),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
