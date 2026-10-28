import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../addresses/screens/my_addresses_screen.dart';
import '../../auth/screens/phone_login_screen.dart';
import '../../booking/screens/my_bookings_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../support/screens/help_support_screen.dart';
import 'account_details_screen.dart';
import 'my_dogs_screen.dart';
import 'privacy_terms_screen.dart';

const Color profileOrange = Color(0xFFFF7900);
const Color profileBackground = Color(0xFFFFFAF5);
const Color profileText = Color(0xFF202020);
const Color profileMuted = Color(0xFF777777);

String _tr(String en, String hi, String bn) {
  switch (appLocale.value.languageCode) {
    case 'hi':
      return hi;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;

            return Scaffold(
              backgroundColor: profileBackground,
              appBar: AppBar(
                backgroundColor: profileBackground,
                elevation: 0,
                title: Text(
                  _tr(
                    'My Profile',
                    'मेरी प्रोफ़ाइल',
                    'আমার প্রোফাইল',
                  ),
                  style: const TextStyle(
                    color: profileText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              body: authSnapshot.connectionState ==
                      ConnectionState.waiting
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
      },
    );
  }

  // --------------------------------------------------
  // SIGNED-OUT PROFILE
  // --------------------------------------------------

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
        Text(
          _tr(
            'Welcome to DOJO WALK',
            'DOJO WALK में आपका स्वागत है',
            'DOJO WALK-এ আপনাকে স্বাগতম',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: profileText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tr(
            'Sign in to manage your profile, dogs and bookings.',
            'अपनी प्रोफ़ाइल, कुत्तों और बुकिंग को मैनेज करने के लिए लॉगिन करें।',
            'আপনার প্রোফাইল, কুকুর এবং বুকিং পরিচালনা করতে লগইন করুন।',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
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
            label: Text(
              _tr(
                'Login with Phone',
                'फोन से लॉगिन करें',
                'ফোন দিয়ে লগইন করুন',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
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
          icon: Icons.support_agent_rounded,
          title: _tr(
            'Help & Support',
            'सहायता और सपोर्ट',
            'সাহায্য ও সাপোর্ট',
          ),
          subtitle: _tr(
            'Get help with DOJO WALK',
            'DOJO WALK से सहायता पाएँ',
            'DOJO WALK-এর সাহায্য নিন',
          ),
          onTap: () => _open(
            context,
            const HelpSupportScreen(),
          ),
        ),

        _menuCard(
          context,
          icon: Icons.privacy_tip_outlined,
          title: _tr(
            'Privacy & Terms',
            'गोपनीयता और नियम',
            'গোপনীয়তা ও শর্তাবলি',
          ),
          subtitle: _tr(
            'Your privacy and account policies',
            'आपकी गोपनीयता और अकाउंट नीतियाँ',
            'আপনার গোপনীয়তা ও অ্যাকাউন্ট নীতি',
          ),
          onTap: () => _open(
            context,
            const PrivacyTermsScreen(),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SIGNED-IN PROFILE
  // --------------------------------------------------

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
            _profileCard(
              context,
              user,
              name,
              photoUrl,
            ),

            const SizedBox(height: 25),

            _sectionTitle(
              _tr(
                'MY ACCOUNT',
                'मेरा अकाउंट',
                'আমার অ্যাকাউন্ট',
              ),
            ),

            // MY PROFILE & ACCOUNT
            _menuCard(
              context,
              icon: Icons.person_outline_rounded,
              title: _tr(
                'My Profile & Account',
                'मेरी प्रोफ़ाइल और अकाउंट',
                'আমার প্রোফাইল ও অ্যাকাউন্ট',
              ),
              subtitle: _tr(
                'Manage your personal details',
                'अपनी व्यक्तिगत जानकारी मैनेज करें',
                'আপনার ব্যক্তিগত তথ্য পরিচালনা করুন',
              ),
              onTap: () => _open(
                context,
                AccountDetailsScreen(user: user),
              ),
            ),

            // MY DOGS
            _menuCard(
              context,
              icon: Icons.pets_rounded,
              title: _tr(
                'My Dogs',
                'मेरे कुत्ते',
                'আমার কুকুর',
              ),
              subtitle: _tr(
                'Manage your saved dogs',
                'अपने सेव किए गए कुत्तों को मैनेज करें',
                'আপনার সংরক্ষিত কুকুর পরিচালনা করুন',
              ),
              onTap: () => _open(
                context,
                const MyDogsScreen(),
              ),
            ),

            // MY BOOKINGS
            _menuCard(
              context,
              icon: Icons.calendar_month_rounded,
              title: _tr(
                'My Bookings',
                'मेरी बुकिंग',
                'আমার বুকিং',
              ),
              subtitle: _tr(
                'View walks and booking details',
                'वॉक और बुकिंग की जानकारी देखें',
                'ওয়াক ও বুকিংয়ের বিবরণ দেখুন',
              ),
              onTap: () => _open(
                context,
                const MyBookingsScreen(),
              ),
            ),

            // SAVED ADDRESSES
            _menuCard(
              context,
              icon: Icons.location_on_outlined,
              title: _tr(
                'Saved Addresses',
                'सेव किए गए पते',
                'সংরক্ষিত ঠিকানা',
              ),
              subtitle: _tr(
                'Manage your pickup locations',
                'अपने पिकअप पते मैनेज करें',
                'আপনার পিকআপের ঠিকানা পরিচালনা করুন',
              ),
              onTap: () => _open(
                context,
                const MyAddressesScreen(),
              ),
            ),

            const SizedBox(height: 15),

            _sectionTitle(
              _tr(
                'SUPPORT & INFORMATION',
                'सहायता और जानकारी',
                'সাহায্য ও তথ্য',
              ),
            ),

            // HELP & SUPPORT
            _menuCard(
              context,
              icon: Icons.support_agent_rounded,
              title: _tr(
                'Help & Support',
                'सहायता और सपोर्ट',
                'সাহায্য ও সাপোর্ট',
              ),
              subtitle: _tr(
                'Get help with a booking',
                'बुकिंग में सहायता पाएँ',
                'বুকিংয়ের জন্য সাহায্য নিন',
              ),
              onTap: () => _open(
                context,
                const HelpSupportScreen(),
              ),
            ),

            // SETTINGS — CORRECT FILE PATH
            _menuCard(
              context,
              icon: Icons.settings_outlined,
              title: _tr(
                'Settings',
                'सेटिंग्स',
                'সেটিংস',
              ),
              subtitle: _tr(
                'Account preferences',
                'अकाउंट की प्राथमिकताएँ',
                'অ্যাকাউন্টের পছন্দসমূহ',
              ),
              onTap: () => _open(
                context,
                const SettingsScreen(),
              ),
            ),

            // PRIVACY & TERMS
            _menuCard(
              context,
              icon: Icons.privacy_tip_outlined,
              title: _tr(
                'Privacy & Terms',
                'गोपनीयता और नियम',
                'গোপনীয়তা ও শর্তাবলি',
              ),
              subtitle: _tr(
                'Privacy policy and terms of service',
                'गोपनीयता नीति और सेवा की शर्तें',
                'গোপনীয়তা নীতি ও পরিষেবার শর্তাবলি',
              ),
              onTap: () => _open(
                context,
                const PrivacyTermsScreen(),
              ),
            ),

            const SizedBox(height: 14),

            // LOG OUT
            _menuCard(
              context,
              icon: Icons.logout_rounded,
              title: _tr(
                'Log Out',
                'लॉग आउट',
                'লগ আউট',
              ),
              subtitle: _tr(
                'Sign out from this device',
                'इस डिवाइस से लॉग आउट करें',
                'এই ডিভাইস থেকে লগ আউট করুন',
              ),
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: () => _confirmLogout(context),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'DOJO WALK • ${_tr('Customer App', 'कस्टमर ऐप', 'কাস্টমার অ্যাপ')}',
                style: const TextStyle(
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

  // --------------------------------------------------
  // PROFILE HEADER
  // --------------------------------------------------

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
                    Text(
                      _tr(
                        'WELCOME TO DOJO WALK',
                        'DOJO WALK में आपका स्वागत है',
                        'DOJO WALK-এ আপনাকে স্বাগতম',
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
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
                    Text(
                      _tr(
                        'Dog Parent 🐾',
                        'डॉग पैरेंट 🐾',
                        'কুকুরের অভিভাবক 🐾',
                      ),
                      style: const TextStyle(
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
              label: Text(
                _tr(
                  'View Profile & Account',
                  'प्रोफ़ाइल और अकाउंट देखें',
                  'প্রোফাইল ও অ্যাকাউন্ট দেখুন',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // REUSABLE WIDGETS
  // --------------------------------------------------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: profileMuted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _readString(
    Map<String, dynamic> data,
    String key,
  ) {
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
        border: Border.all(
          color: const Color(0xFFF0ECE8),
        ),
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
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
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

  // --------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  // --------------------------------------------------
  // LOG OUT
  // --------------------------------------------------

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _tr(
              'Log out?',
              'लॉग आउट करें?',
              'লগ আউট করবেন?',
            ),
          ),
          content: Text(
            _tr(
              'Are you sure you want to log out of DOJO WALK?',
              'क्या आप DOJO WALK से लॉग आउट करना चाहते हैं?',
              'আপনি কি DOJO WALK থেকে লগ আউট করতে চান?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                _tr('Stay', 'नहीं', 'থাকুন'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: profileOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                _tr(
                  'Log Out',
                  'लॉग आउट',
                  'লগ আউট',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Could not log out. Please try again.',
              'लॉग आउट नहीं हो पाया। कृपया फिर कोशिश करें।',
              'লগ আউট করা যায়নি। আবার চেষ্টা করুন।',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
