
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../booking/screens/my_bookings_screen.dart';
import '../../support/screens/help_support_screen.dart';
import 'my_dogs_screen.dart';

const Color profileOrange = Color(0xFFFF7900);
const Color profileBackground = Color(0xFFFFFAF5);
const Color profileText = Color(0xFF252525);
const Color profileMuted = Color(0xFF777777);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: profileOrange,
                ),
              );
            }

            final user = authSnapshot.data;

            if (user == null) {
              return _signedOutView(context);
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                final data = userSnapshot.data?.data() ??
                    <String, dynamic>{};

                final name = (data['name'] ?? 'DOJO WALK Customer')
                    .toString();
                final phone = (data['phoneNumber'] ??
                        user.phoneNumber ??
                        'Phone not available')
                    .toString();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: profileOrange,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.pets_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DOJO WALK',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: profileText,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'YOUR CUSTOMER ACCOUNT',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: profileMuted,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showMessage(
                            context,
                            'Settings are coming soon.',
                          ),
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: profileText,
                          ),
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Customer profile card
                    Container(
                      padding: const EdgeInsets.all(18),
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
                            width: 62,
                            height: 62,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              name.trim().isNotEmpty
                                  ? name.trim()[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'CUSTOMER ACCOUNT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    const Text(
                      'YOUR ACCOUNT',
                      style: TextStyle(
                        color: profileMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _menuCard(
                      context,
                      icon: Icons.pets_rounded,
                      title: 'My Dogs',
                      subtitle: 'Manage your dogs and their details',
                      onTap: () => _navigate(
                        context,
                        const MyDogsScreen(),
                      ),
                    ),
                    _menuCard(
                      context,
                      icon: Icons.calendar_month_rounded,
                      title: 'My Bookings',
                      subtitle: 'View walks, details and booking status',
                      onTap: () => _navigate(
                        context,
                        const MyBookingsScreen(),
                      ),
                    ),
                    _menuCard(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      subtitle: 'Manage your pickup locations',
                      onTap: () => _showMessage(
                        context,
                        'Saved Addresses will be available here.',
                      ),
                    ),
                    _menuCard(
                      context,
                      icon: Icons.repeat_rounded,
                      title: 'Regular Walk Plans',
                      subtitle: 'Manage your regular walking plans',
                      onTap: () => _showMessage(
                        context,
                        'Regular Walk Plans will be available here.',
                      ),
                    ),
                    _menuCard(
                      context,
                      icon: Icons.support_agent_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help with bookings and your account',
                      onTap: () => _navigate(
                        context,
                        const HelpSupportScreen(),
                      ),
                    ),
                    _menuCard(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Account and app preferences',
                      onTap: () => _showMessage(
                        context,
                        'Settings are coming soon.',
                      ),
                    ),
                    _menuCard(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      subtitle: 'Sign out of your account',
                      iconColor: const Color(0xFFD64545),
                      iconBackground: const Color(0xFFFFEEEE),
                      onTap: () => _confirmLogout(context),
                    ),

                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'DOJO WALK • YOUR DOG, OUR CARE',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _signedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              color: profileOrange,
              size: 70,
            ),
            const SizedBox(height: 14),
            const Text(
              'Login to Your Account',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: profileText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to manage your dogs and bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: profileMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showMessage(
                  context,
                  'Connect your existing login screen here.',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: profileOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('LOGIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = profileOrange,
    Color iconBackground = const Color(0xFFFFF0E3),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF0E6DD)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: title == 'Log Out'
                              ? const Color(0xFFD64545)
                              : profileText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: profileMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF999999),
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text(
          'Are you sure you want to log out of DOJO WALK?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: profileOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
