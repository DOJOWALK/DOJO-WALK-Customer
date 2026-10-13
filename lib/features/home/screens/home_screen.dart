
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../address/models/saved_address.dart';
import '../../address/services/address_service.dart';
import '../../address/screens/address_form_screen.dart';
import '../../booking/screens/choose_walk_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/my_dogs_screen.dart';
import '../../support/screens/help_support_screen.dart';

const Color dojoOrange = Color(0xFFFF7900);
const Color dojoBackground = Color(0xFFFFFAF5);
const Color dojoText = Color(0xFF202020);
const Color dojoMuted = Color(0xFF777777);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedAddress = 'Select your location';
  SavedAddress? _selectedSavedAddress;

  final AddressService _addressService = AddressService();

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      final addresses = await _addressService.getAddresses();

      if (!mounted || addresses.isEmpty) return;

      final selected = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );

      setState(() {
        _selectedSavedAddress = selected;
        _selectedAddress = _formatSavedAddress(selected);
      });
    } catch (_) {
      // Keep the prompt visible if addresses cannot be loaded.
    }
  }

  String _formatSavedAddress(SavedAddress address) {
    final parts = [
      address.flatHouse,
      address.buildingSociety,
      address.area,
      address.city,
      address.pincode,
    ].where((part) => part.trim().isNotEmpty).toList();

    if (parts.isEmpty) return address.label;

    return '${address.label} · ${parts.join(', ')}';
  }

  Future<void> _openAddressForm(
    BuildContext sheetContext,
  ) async {
    await Navigator.of(sheetContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AddressFormScreen(),
      ),
    );

    // The address list uses a Firestore stream, so newly saved
    // addresses will appear automatically when the stream updates.
  }

  Future<void> _openAddressSelector() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to choose a saved address.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dojoBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.76,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Choose Pickup Address',
                          style: TextStyle(
                            color: dojoText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Where should the walker pick up your dog?',
                      style: TextStyle(
                        color: dojoMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: StreamBuilder<List<SavedAddress>>(
                    stream: _addressService.watchAddresses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Could not load addresses. '
                              'Please check your connection and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: dojoMuted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: dojoOrange,
                          ),
                        );
                      }

                      final addresses = snapshot.data ?? [];

                      if (addresses.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_off_outlined,
                                  size: 48,
                                  color: dojoOrange,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No saved addresses yet',
                                  style: TextStyle(
                                    color: dojoText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  'Add your home or another pickup location.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: dojoMuted,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _openAddressForm(sheetContext),
                                  icon: const Icon(
                                    Icons.add_location_alt_rounded,
                                  ),
                                  label: const Text('Add New Address'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: dojoOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: addresses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          final details = [
                            address.flatHouse,
                            address.buildingSociety,
                            address.area,
                            address.landmark,
                            address.city,
                            address.pincode,
                          ]
                              .where((part) => part.trim().isNotEmpty)
                              .join(', ');

                          final isSelected =
                              _selectedSavedAddress?.id == address.id;

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(sheetContext).pop(address);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? dojoOrange
                                        : const Color(0xFFEEEEEE),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0E3),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        address.label == 'Home'
                                            ? Icons.home_rounded
                                            : address.label == 'Work'
                                                ? Icons.work_outline_rounded
                                                : Icons.location_on_outlined,
                                        color: dojoOrange,
                                        size: 23,
                                      ),
                                    ),
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
                                                    color: dojoText,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              if (address.isDefault)
                                                Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 7,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFFEAD8,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'DEFAULT',
                                                    style: TextStyle(
                                                      color: dojoOrange,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            details.isEmpty
                                                ? 'Address details unavailable'
                                                : details,
                                            style: const TextStyle(
                                              color: dojoMuted,
                                              fontSize: 12,
                                              height: 1.45,
                                            ),
                                          ),
                                          if (address.pickupInstructions
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Pickup instructions: '
                                              '${address.pickupInstructions}',
                                              style: const TextStyle(
                                                color: dojoMuted,
                                                fontSize: 11,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Tap to select',
                                            style: TextStyle(
                                              color: dojoOrange,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.chevron_right_rounded,
                                      color: isSelected
                                          ? dojoOrange
                                          : dojoMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _openAddressForm(sheetContext),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text(
                        'Add New Address',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dojoOrange,
                        side: const BorderSide(color: dojoOrange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedSavedAddress = selected;
        _selectedAddress = _formatSavedAddress(selected);
      });
    }
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  void _openBooking() {
    _openScreen(const ChooseWalkScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dojoBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildAddressSelector()),
            SliverToBoxAdapter(child: _buildBookingSection()),
            SliverToBoxAdapter(child: _buildMyDogsSection()),
            SliverToBoxAdapter(child: _buildHelpSection()),
            const SliverToBoxAdapter(
              child: SizedBox(height: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: dojoOrange,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOJO WALK',
                  style: TextStyle(
                    color: dojoText,
                    fontSize: 21,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dog Walking',
                  style: TextStyle(
                    color: dojoMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                _openScreen(const NotificationsScreen());
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: dojoText,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _openAddressSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFEEEEEE),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: dojoOrange,
                  size: 23,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PICKUP LOCATION',
                        style: TextStyle(
                          color: dojoMuted,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: dojoText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: dojoMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: const Color(0xFFF0E8DF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: dojoOrange.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: dojoOrange,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dog Walking',
                        style: TextStyle(
                          color: dojoText,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Choose the walk that suits your dog.',
                        style: TextStyle(
                          color: dojoMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 21),
            Row(
              children: [
                Expanded(
                  child: _walkTypeChip(
                    icon: Icons.directions_walk_rounded,
                    title: 'One-Time',
                    subtitle: 'A single walk',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _walkTypeChip(
                    icon: Icons.event_repeat_rounded,
                    title: 'Regular',
                    subtitle: 'Daily walks',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 21),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _openBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: dojoOrange,
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
                      'BOOK A WALK',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 9),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walkTypeChip({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: dojoBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF0E8DF),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: dojoOrange, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dojoText,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dojoMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDogsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: _sectionCard(
        icon: Icons.pets_rounded,
        title: 'My Dogs',
        subtitle:
            'Save your dog’s details once and reuse them when booking.',
        actionLabel: 'Manage Dogs',
        onTap: () => _openScreen(const MyDogsScreen()),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: _sectionCard(
        icon: Icons.support_agent_rounded,
        title: 'Help & Support',
        subtitle:
            'Find answers about bookings, walkers and dog safety.',
        actionLabel: 'Get Help',
        onTap: () => _openScreen(const HelpSupportScreen()),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dojoOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: dojoOrange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: dojoText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: dojoMuted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: dojoOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: dojoMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
