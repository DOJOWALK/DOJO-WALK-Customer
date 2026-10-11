import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

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
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: SafeArea(
            child: authSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !authSnapshot.hasData
                ? const Center(
                    child: CircularProgressIndicator(
                      color: profileOrange,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      10,
                      18,
                      28,
                    ),
                    children: [
                      if (user == null)
                        _buildSignedOutHeader()
                      else
                        StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data();

                            final savedName =
                                data?['name']?.toString().trim() ?? '';
                            final savedPhone =
                                data?['phoneNumber']?.toString().trim() ??
                                    '';

                            final name = savedName.isNotEmpty
                                ? savedName
                                : (user.displayName?.trim().isNotEmpty ==
                                        true
                                    ? user.displayName!
                                    : 'DOJO WALK Customer');

                            final phone = user.phoneNumber ??
                                (savedPhone.isNotEmpty
                                    ? savedPhone
                                    : 'Mobile number not available');

                            return _buildProfileHeader(
                              name: name,
                              phone: phone,
                              isLoggedIn: true,
                            );
                          },
                        ),

                      const SizedBox(height: 26),

                      _sectionTitle('MY ACCOUNT'),

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
                        subtitle: 'View and track your dog walks',
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
                        onTap: () => _showMessage(
                          context,
                          'Saved Addresses will be connected next.',
                        ),
                      ),

                      _buildMenuItem(
                        context,
                        icon: Icons.calendar_month_rounded,
                        title: 'Regular Walk Plans',
                        subtitle: 'Manage recurring walk preferences',
                        onTap: () => _showMessage(
                          context,
                          'Regular Walk Plans will be connected next.',
                        ),
                      ),

                      const SizedBox(height: 22),

                      _sectionTitle('COMMUNICATION'),

                      _buildMenuItem(
                        context,
                        icon: Icons.notifications_active_outlined,
                        title: 'Notifications',
                        subtitle: 'Booking updates and important alerts',
                        onTap: () => _showMessage(
                          context,
                          'Notifications will be connected next.',
                        ),
                      ),

                      _buildMenuItem(
                        context,
                        icon: Icons.support_agent_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get help with your bookings',
                        onTap: () => _showMessage(
                          context,
                          'Help & Support will be connected next.',
                        ),
                      ),

                      const SizedBox(height: 22),

                      _sectionTitle('PREFERENCES'),

                      _buildMenuItem(
                        context,
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Account and app preferences',
                        onTap: () => _showMessage(
                          context,
                          'Settings will be available here.',
                        ),
                      ),

                      if (user != null) ...[
                        const SizedBox(height: 22),
                        _sectionTitle('ACCOUNT SECURITY'),
                        _buildMenuItem(
                          context,
                          icon: Icons.logout_rounded,
                          title: 'Log Out',
                          subtitle: 'Sign out from your account',
                          isDestructive: true,
                          onTap: () => _confirmLogout(context),
                        ),
                      ],

                      const SizedBox(height: 26),

                      const Icon(
                        Icons.pets_rounded,
                        color: profileOrange,
                        size: 27,
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'DOJO WALK',
                          style: TextStyle(
                            color: profileText,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Happy walks. Happier dogs.',
                          style: TextStyle(
                            color: profileMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSignedOutHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7900),
            Color(0xFFFF9D42),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Color(0x44FFFFFF),
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Welcome to DOJO WALK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Sign in when you are ready to manage your account and bookings.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'You are currently signed out',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String phone,
    required bool isLoggedIn,
  }) {
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'D';

    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7900),
            Color(0xFFFF9D42),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: profileOrange.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLoggedIn ? 'Customer Account' : 'Guest Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: profileMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
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
    final color = isDestructive ? Colors.red.shade700 : profileText;
    final iconColor = isDestructive ? Colors.red : profileOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFEFEFEF),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        leading: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 23,
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: profileMuted,
              fontSize: 11,
              height: 1.4,
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Log out?'),
          content: const Text(
            'Are you sure you want to log out of DOJO WALK?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: profileOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
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
    } catch (_) {
      if (!context.mounted) return;

      _showMessage(
        context,
        'Could not log out. Please try again.',
      );
    }
  }
}
