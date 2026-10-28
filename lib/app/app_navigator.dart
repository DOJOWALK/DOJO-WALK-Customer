
import 'package:flutter/material.dart';

import 'locale_controller.dart';
import 'theme.dart';
import '../features/home/screens/home_screen.dart';
import '../features/booking/screens/my_bookings_screen.dart';
import '../features/profile/screens/profile_screen.dart';

const Color navOrange = DojoWalkTheme.primary;
const Color navBackground = DojoWalkTheme.background;
const Color navMuted = DojoWalkTheme.mutedText;

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const MyBookingsScreen(),
    const ProfileScreen(),
  ];

  void _selectTab(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        final language = locale.languageCode;

        String translate({
          required String en,
          required String hi,
          required String bn,
        }) {
          switch (language) {
            case 'hi':
              return hi;
            case 'bn':
              return bn;
            default:
              return en;
          }
        }

        return Scaffold(
          backgroundColor: navBackground,
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildItem(
                      index: 0,
                      icon: Icons.home_rounded,
                      label: translate(
                        en: 'Home',
                        hi: 'होम',
                        bn: 'হোম',
                      ),
                    ),
                    _buildItem(
                      index: 1,
                      icon: Icons.receipt_long_rounded,
                      label: translate(
                        en: 'My Bookings',
                        hi: 'मेरी बुकिंग',
                        bn: 'আমার বুকিং',
                      ),
                    ),
                    _buildItem(
                      index: 2,
                      icon: Icons.person_outline_rounded,
                      label: translate(
                        en: 'Profile',
                        hi: 'प्रोफ़ाइल',
                        bn: 'প্রোফাইল',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: selected ? navOrange : navMuted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: selected ? navOrange : navMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
