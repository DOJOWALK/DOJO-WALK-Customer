
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
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ??
                    <String, dynamic>{};

                final name = (data['name'] ?? 'Customer Name')
                    .toString();
                final phone = (data['phoneNumber'] ??
                        user.phoneNumber ??
                        'Not available')
                    .toString();
                final photoUrl = (data['photoUrl'] ?? '').toString();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
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
                          child: Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: profileText,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => _message(
                            context,
                            'Settings screen is not connected yet.',
                          ),
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: profileText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Centered profile card
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _open(
                          context,
                          MyProfileAccountScreen(
                            user: user,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFF0E5DA),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: profileOrange,
                                ),
                                child: CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFFFFF0DF),
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 54,
                                          color: profileOrange,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: profileText,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'DOJO WALK Customer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: profileOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _accountStatus(data),
                              const SizedBox(height: 14),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'View Profile & Account',
                                    style: TextStyle(
                                      color: profileMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: profileOrange,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                      icon: Icons.person_outline_rounded,
                      title: 'My Profile & Account',
                      subtitle: 'Personal information and account details',
                      onTap: () => _open(
                        context,
                        MyProfileAccountScreen(user: user),
                      ),
                    ),
                    _menuCard(
                      icon: Icons.pets_rounded,
                      title: 'My Dogs',
                      subtitle: 'Manage your dogs and their details',
                      onTap: () => _open(
                        context,
                        const MyDogsScreen(),
                      ),
                    ),
                    _menuCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'My Bookings',
                      subtitle: 'View walks, details and booking status',
                      onTap: () => _open(
                        context,
                        const MyBookingsScreen(),
                      ),
                    ),
                    _menuCard(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      subtitle: 'Manage your pickup locations',
                      onTap: () => _message(
                        context,
                        'Connect your existing Saved Addresses screen here.',
                      ),
                    ),
                    _menuCard(
                      icon: Icons.local_offer_outlined,
                      title: 'Coupons & Offers',
                      subtitle: 'View discount offers and coupon information',
                      onTap: () => _open(
                        context,
                        const CouponsOffersScreen(),
                      ),
                    ),
                    _menuCard(
                      icon: Icons.support_agent_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help with bookings and your account',
                      onTap: () => _open(
                        context,
                        const HelpSupportScreen(),
                      ),
                    ),
                    _menuCard(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Account and app preferences',
                      onTap: () => _message(
                        context,
                        'Settings screen is not connected yet.',
                      ),
                    ),
                    _menuCard(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy & Terms',
                      subtitle: 'Privacy policy and terms of service',
                      onTap: () => _message(
                        context,
                        'Privacy & Terms screen is not connected yet.',
                      ),
                    ),
                    _menuCard(
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

  static Widget _accountStatus(Map<String, dynamic> data) {
    final rawStatus =
        (data['accountStatus'] ?? data['status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

    final bool isActive =
        data['isActive'] == true || rawStatus == 'active';
    final bool isInactive =
        data['isActive'] == false ||
        rawStatus == 'inactive' ||
        rawStatus == 'suspended' ||
        rawStatus == 'disabled';

    final label = isActive
        ? 'Account Active'
        : isInactive
            ? 'Account Inactive'
            : 'Account Status Unavailable';

    final color = isActive
        ? const Color(0xFF218447)
        : isInactive
            ? const Color(0xFFD64545)
            : profileMuted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : isInactive
                    ? Icons.cancel_rounded
                    : Icons.info_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
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
              style: TextStyle(color: profileMuted),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _message(
                  context,
                  'Connect your existing phone login screen here.',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: profileOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('LOGIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
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
                  child: Icon(icon, color: iconColor, size: 23),
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

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _message(BuildContext context, String message) {
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

// My Profile & Account
class MyProfileAccountScreen extends StatelessWidget {
  final User user;

  const MyProfileAccountScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: profileBackground,
        foregroundColor: profileText,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load profile information.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: profileOrange,
              ),
            );
          }

          final data = snapshot.data!.data() ??
              <String, dynamic>{};

          final name = (data['name'] ?? 'Customer Name').toString();
          final phone = (data['phoneNumber'] ??
                  user.phoneNumber ??
                  'Not available')
              .toString();
          final gender = (data['gender'] ?? 'Not provided').toString();
          final dob = data['dateOfBirth'];
          final photoUrl = (data['photoUrl'] ?? '').toString();

          String dateText = 'Not provided';
          if (dob is Timestamp) {
            final date = dob.toDate();
            dateText =
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year}';
          } else if (dob is String && dob.isNotEmpty) {
            dateText = dob;
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFF0E5DA),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFFFF0DF),
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              color: profileOrange,
                              size: 48,
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: profileText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'DOJO WALK Customer',
                      style: TextStyle(
                        color: profileOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _editName(
                          context,
                          user,
                          name,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: profileOrange,
                          side: const BorderSide(
                            color: profileOrange,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'PERSONAL INFORMATION',
                style: TextStyle(
                  color: profileMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              _detailCard(
                Icons.person_outline,
                'Full Name',
                name,
              ),
              _detailCard(
                Icons.phone_outlined,
                'Phone Number',
                phone,
              ),
              _detailCard(
                Icons.wc_outlined,
                'Gender',
                gender,
              ),
              _detailCard(
                Icons.calendar_today_outlined,
                'Date of Birth',
                dateText,
              ),
              const SizedBox(height: 18),
              const Text(
                'ACCOUNT DETAILS',
                style: TextStyle(
                  color: profileMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              _detailCard(
                Icons.verified_user_outlined,
                'Account Type',
                'DOJO WALK Customer',
              ),
              _detailCard(
                Icons.info_outline,
                'Account Status',
                _statusText(data),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _statusText(Map<String, dynamic> data) {
    final status = (data['accountStatus'] ?? data['status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    if (data['isActive'] == true || status == 'active') {
      return 'Account Active';
    }
    if (data['isActive'] == false ||
        status == 'inactive' ||
        status == 'suspended' ||
        status == 'disabled') {
      return 'Account Inactive';
    }
    return 'Status not specified';
  }

  static Widget _detailCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFF0E5DA),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: profileOrange, size: 23),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: profileMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: profileText,
                    fontSize: 14,
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

  static Future<void> _editName(
    BuildContext context,
    User user,
    String currentName,
  ) async {
    final controller = TextEditingController(
      text: currentName == 'Customer Name' ? '' : currentName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: profileOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName == null || newName.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': newName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update name. Please try again.'),
        ),
      );
    }
  }
}

// Coupons & Offers
class CouponsOffersScreen extends StatelessWidget {
  const CouponsOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileBackground,
      appBar: AppBar(
        title: const Text('Coupons & Offers'),
        backgroundColor: profileBackground,
        foregroundColor: profileText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF7900),
                  Color(0xFFFF9D42),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                SizedBox(height: 14),
                Text(
                  'Special Offers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Look out for DOJO WALK discounts at checkout.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'AVAILABLE COUPONS',
            style: TextStyle(
              color: profileMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFF0E5DA),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 42,
                  color: profileOrange,
                ),
                SizedBox(height: 12),
                Text(
                  'No Offers Available Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: profileText,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'New coupon offers will appear here when they are '
                  'published by DOJO WALK.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: profileMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Coupon codes and discounts must be validated during '
            'booking before a discount is applied.',
            style: TextStyle(
              color: profileMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
