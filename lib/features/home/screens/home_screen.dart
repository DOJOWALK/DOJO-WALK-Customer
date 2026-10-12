
import 'package:flutter/material.dart';

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

  Future<void> _openAddressSelector() async {
    final controller = TextEditingController(
      text: _selectedAddress == 'Select your location'
          ? ''
          : _selectedAddress,
    );

    final address = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dojoBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup Location',
                style: TextStyle(
                  color: dojoText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Where should the walker pick up your dog?',
                style: TextStyle(
                  color: dojoMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Enter area or full address',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: dojoOrange,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFE7E7E7),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFE7E7E7),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: dojoOrange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();

                    if (value.isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your location.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(sheetContext).pop(value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dojoOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Save Location',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (address != null && mounted) {
      setState(() => _selectedAddress = address);
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
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildAddressSelector(),
            ),
            SliverToBoxAdapter(
              child: _buildBookingSection(),
            ),
            SliverToBoxAdapter(
              child: _buildMyDogsSection(),
            ),
            SliverToBoxAdapter(
              child: _buildHelpSection(),
            ),
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
        subtitle: 'Save your dog’s details once and reuse them when booking.',
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
        subtitle: 'Find answers about bookings, walkers and dog safety.',
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
