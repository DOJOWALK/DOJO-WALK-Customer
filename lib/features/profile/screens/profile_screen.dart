import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../booking/screens/my_bookings_screen.dart';
import '../../booking/screens/my_dogs_screen.dart';

const Color profileOrange = Color(0xFFFF7900);
const Color profileBackground = Color(0xFFFFFAF5);
const Color profileText = Color(0xFF202020);
const Color profileMuted = Color(0xFF777777);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final phone = user?.phoneNumber ?? 'Mobile number not available';
    final name = user?.displayName ?? 'DOJO WALK Customer';

    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        backgroundColor: profileBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: profileText,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildProfileHeader(name, phone),
            const SizedBox(height: 25),

            const Text(
              'MY ACCOUNT',
              style: TextStyle(
                color: profileMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            _buildMenuItem(
              context,
              icon: Icons.pets_rounded,
              title: 'My Dogs',
              subtitle: 'Manage your dogs and their details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyDogsScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.receipt_long_rounded,
              title: 'My Bookings',
              subtitle: 'View your dog walking bookings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              subtitle: 'Manage your pickup locations',
              onTap: () {
                _showMessage(
                  context,
                  'Saved Addresses will be connected next.',
                );
              },
            ),

            const SizedBox(height: 22),

            const Text(
              'HELP & SETTINGS',
              style: TextStyle(
                color: profileMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            _buildMenuItem(
              context,
              icon: Icons.support_agent_rounded,
              title: 'Help & Support',
              subtitle: 'Get help with your bookings',
              onTap: () {
                _showMessage(
                  context,
                  'Help & Support will be connected next.',
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Booking updates and alerts',
              onTap: () {
                _showMessage(
                  context,
                  'Notifications will be connected next.',
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Account and app preferences',
              onTap: () {
                _showMessage(
                  context,
                  'Settings will be available here.',
                );
              },
            ),

            const SizedBox(height: 20),

            if (user != null)
              _buildMenuItem(
                context,
                icon: Icons.logout_rounded,
                title: 'Log Out',
                subtitle: 'Sign out from your account',
                isDestructive: true,
                onTap: () {
                  _confirmLogout(context);
                },
              ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                'DOJO WALK • Happy walks. Happier dogs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: profileMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7900),
            Color(0xFFFF9D42),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            height: 66,
            width: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Customer Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red.shade700
        : profileText;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEFEFEF),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 7,
        ),
        leading: Container(
          height: 43,
          width: 43,
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.08)
                : profileOrange.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : profileOrange,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: profileMuted,
            fontSize: 11,
            height: 1.5,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: profileMuted,
        ),
        onTap: onTap,
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

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out of DOJO WALK?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: profileOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!context.mounted) return;

      _showMessage(
        context,
        'Could not log out. Please try again.',
      );
    }
  }
}
