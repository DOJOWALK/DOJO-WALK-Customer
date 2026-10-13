
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../addresses/screens/my_addresses_screen.dart';
import '../../auth/screens/phone_login_screen.dart';
import '../../booking/screens/my_bookings_screen.dart';
import '../../support/screens/help_support_screen.dart';
import 'account_details_screen.dart';
import 'my_dogs_screen.dart';

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
            title: const Text(
              'My Profile',
              style: TextStyle(
                color: profileText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: authSnapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: CircularProgressIndicator(
                    color: profileOrange,
                  ),
                )
              : user == null
                  ? _signedOutView(context)
                  : _signedInView(context, user),
        );
      },
    );
  }

  Widget _signedOutView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 24),
        const Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Color(0xFFFFEAD8),
            child: Icon(
              Icons.person_outline_rounded,
              size: 48,
              color: profileOrange,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Welcome to DOJO WALK',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: profileText,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to manage your profile, dogs and bookings.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: profileMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 51,
          child: ElevatedButton.icon(
            onPressed: () => _open(
              context,
              const PhoneLoginScreen(),
            ),
            icon: const Icon(Icons.phone_android_rounded),
            label: const Text(
              'Login with Phone',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: profileOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _menuCard(
          context,
          icon: Icons.local_offer_outlined,
          title: 'Coupons & Offers',
          subtitle: 'View available offers',
          onTap: () => _open(context, const CouponsOffersScreen()),
        ),
        _menuCard(
          context,
          icon: Icons.support_agent_rounded,
          title: 'Help & Support',
          subtitle: 'Get help with DOJO WALK',
          onTap: () => _open(context, const HelpSupportScreen()),
        ),
        _menuCard(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy & Terms',
          subtitle: 'Your privacy and account policies',
          onTap: () => _open(context, const PrivacyTermsScreen()),
        ),
      ],
    );
  }

  Widget _signedInView(BuildContext context, User user) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final storedName = _readString(data, 'name');
        final name = storedName.isNotEmpty
            ? storedName
            : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'DOJO WALK Customer');

        final photoUrl = _readString(data, 'photoUrl');

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _profileCard(context, user, name, photoUrl),
            const SizedBox(height: 25),
            _sectionTitle('MY ACCOUNT'),
            _menuCard(
              context,
              icon: Icons.person_outline_rounded,
              title: 'My Profile & Account',
              subtitle: 'Manage your personal details',
              onTap: () => _open(
                context,
                AccountDetailsScreen(user: user),
              ),
            ),
            _menuCard(
              context,
              icon: Icons.pets_rounded,
              title: 'My Dogs',
              subtitle: 'Manage your saved dogs',
              onTap: () => _open(context, const MyDogsScreen()),
            ),
            _menuCard(
              context,
              icon: Icons.calendar_month_rounded,
              title: 'My Bookings',
              subtitle: 'View walks and booking details',
              onTap: () => _open(context, const MyBookingsScreen()),
            ),
            _menuCard(
              context,
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              subtitle: 'Manage your pickup locations',
              onTap: () => _open(context, const MyAddressesScreen()),
            ),
            _menuCard(
              context,
              icon: Icons.local_offer_outlined,
              title: 'Coupons & Offers',
              subtitle: 'See offers available to your account',
              onTap: () => _open(context, const CouponsOffersScreen()),
            ),
            const SizedBox(height: 15),
            _sectionTitle('SUPPORT & INFORMATION'),
            _menuCard(
              context,
              icon: Icons.support_agent_rounded,
              title: 'Help & Support',
              subtitle: 'Get help with a booking',
              onTap: () => _open(context, const HelpSupportScreen()),
            ),
            _menuCard(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Account preferences',
              onTap: () => _open(context, const SettingsScreen()),
            ),
            _menuCard(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Terms',
              subtitle: 'Privacy policy and terms of service',
              onTap: () => _open(context, const PrivacyTermsScreen()),
            ),
            const SizedBox(height: 14),
            _menuCard(
              context,
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'Sign out from this device',
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: () => _confirmLogout(context),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'DOJO WALK • Customer App',
                style: TextStyle(
                  color: profileMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _profileCard(
    BuildContext context,
    User user,
    String name,
    String photoUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF7900),
            Color(0xFFFFA34D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: profileOrange.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFFFEAD8),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: profileOrange,
                          size: 42,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WELCOME TO DOJO WALK',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Dog Parent 🐾',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 27,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _open(
                context,
                AccountDetailsScreen(user: user),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: profileOrange,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.manage_accounts_rounded),
              label: const Text(
                'View Profile & Account',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: profileMuted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is String ? value.trim() : '';
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = profileOrange,
    Color titleColor = profileText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF0ECE8)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 6,
        ),
        leading: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: iconColor == Colors.red
                ? const Color(0xFFFFEEEE)
                : const Color(0xFFFFF0E3),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
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
              fontSize: 12,
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

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Are you sure you want to log out of DOJO WALK?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
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
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (context.mounted) {
        _message(context, 'Could not log out. Please try again.');
      }
    }
  }

  void _message(BuildContext context, String message) {
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

class CouponsOffersScreen extends StatelessWidget {
  const CouponsOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        backgroundColor: profileBackground,
        title: const Text(
          'Coupons & Offers',
          style: TextStyle(
            color: profileText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEAD8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  size: 40,
                  color: profileOrange,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Offers Available Yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: profileText,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'New DOJO WALK offers will appear here when they become available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: profileMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        backgroundColor: profileBackground,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: profileText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Account settings will be available here soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: profileMuted),
          ),
        ),
      ),
    );
  }
}

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        backgroundColor: profileBackground,
        title: const Text(
          'Privacy & Terms',
          style: TextStyle(
            color: profileText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Your Privacy',
            style: TextStyle(
              color: profileText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'DOJO WALK uses your account details to provide dog-walking '
            'services, manage bookings and support your requests. '
            'Your data should be handled according to the service privacy policy.',
            style: TextStyle(
              color: profileMuted,
              height: 1.6,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Terms of Service',
            style: TextStyle(
              color: profileText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please confirm service details, pickup instructions and booking '
            'information before submitting a booking. Cancellation, refunds '
            'and service rules are subject to DOJO WALK’s published policies.',
            style: TextStyle(
              color: profileMuted,
              height: 1.6,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Note: Replace this draft with your approved legal Privacy Policy '
            'and Terms before launching the app publicly.',
            style: TextStyle(
              color: Colors.deepOrange,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
