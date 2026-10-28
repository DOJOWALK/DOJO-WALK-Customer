
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../addresses/models/saved_address.dart';
import '../../addresses/services/address_service.dart';
import '../../addresses/screens/address_form_screen.dart';
import '../../booking/screens/choose_walk_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/my_dogs_screen.dart';
import '../../support/screens/help_support_screen.dart';

const Color dojoOrange = DojoWalkTheme.primary;
const Color dojoBackground = DojoWalkTheme.background;
const Color dojoText = DojoWalkTheme.text;
const Color dojoMuted = DojoWalkTheme.mutedText;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AddressService _addressService = AddressService();

  SavedAddress? _selectedSavedAddress;
  String _selectedAddress = 'Select your location';
  bool _loadingAddress = true;

  String get _language => appLocale.value.languageCode;

  String _t(String en, String hi, String bn) {
    switch (_language) {
      case 'hi':
        return hi;
      case 'bn':
        return bn;
      default:
        return en;
    }
  }

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_handleLocaleChanged);
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    appLocale.removeListener(_handleLocaleChanged);
    super.dispose();
  }

  void _handleLocaleChanged() {
    if (mounted) setState(() {});
  }

  String _clean(String? value) => (value ?? '').trim();

  String _formatSavedAddress(SavedAddress address) {
    final parts = <String>[
      _clean(address.flatHouse),
      _clean(address.buildingSociety),
      _clean(address.area),
      _clean(address.city),
      _clean(address.pincode),
    ].where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      final label = _clean(address.label);
      return label.isEmpty
          ? _t('Saved Address', 'सेव किया गया पता', 'সংরক্ষিত ঠিকানা')
          : label;
    }

    final label = _clean(address.label);
    final details = parts.join(', ');
    return label.isEmpty ? details : '$label · $details';
  }

  Future<void> _loadDefaultAddress() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) {
        setState(() => _loadingAddress = false);
      }
      return;
    }

    try {
      final addresses = await _addressService.getAddresses();

      if (!mounted) return;

      if (addresses.isEmpty) {
        setState(() {
          _selectedSavedAddress = null;
          _selectedAddress = _t(
            'Select your location',
            'अपनी लोकेशन चुनें',
            'আপনার লোকেশন বেছে নিন',
          );
          _loadingAddress = false;
        });
        return;
      }

      final SavedAddress selected = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );

      setState(() {
        _selectedSavedAddress = selected;
        _selectedAddress = _formatSavedAddress(selected);
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _openBooking() {
    _openScreen(const ChooseWalkScreen());
  }

  Future<void> _openAddressForm() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showMessage(
        _t(
          'Please log in to manage saved addresses.',
          'सेव किए गए पते मैनेज करने के लिए लॉग इन करें।',
          'সংরক্ষিত ঠিকানা পরিচালনা করতে লগ ইন করুন।',
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => AddressFormScreen(address: null),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _loadDefaultAddress();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openAddressSelector() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showMessage(
        _t(
          'Please log in to select a saved address.',
          'सेव किया गया पता चुनने के लिए लॉग इन करें।',
          'সংরক্ষিত ঠিকানা বেছে নিতে লগ ইন করুন।',
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: dojoOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _t(
                            'Choose Pickup Address',
                            'पिकअप का पता चुनें',
                            'পিকআপের ঠিকানা বেছে নিন',
                          ),
                          style: const TextStyle(
                            color: dojoText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<SavedAddress>>(
                    stream: _addressService.watchAddresses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _t(
                                'Unable to load addresses. Please try again.',
                                'पते लोड नहीं हुए। कृपया फिर कोशिश करें।',
                                'ঠিকানা লোড করা যায়নি। আবার চেষ্টা করুন।',
                              ),
                              textAlign: TextAlign.center,
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

                      final addresses =
                          snapshot.data ?? <SavedAddress>[];

                      if (addresses.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_off_outlined,
                                  size: 42,
                                  color: dojoMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _t(
                                    'No saved addresses yet.',
                                    'अभी कोई पता सेव नहीं है।',
                                    'এখনও কোনো ঠিকানা সংরক্ষিত নেই।',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: dojoText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _t(
                                    'Add an address to use it for pickup.',
                                    'पिकअप के लिए एक पता जोड़ें।',
                                    'পিকআপের জন্য একটি ঠিকানা যোগ করুন।',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: dojoMuted),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: addresses.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          final isSelected =
                              _selectedSavedAddress?.id == address.id;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFF0E3),
                              child: Icon(
                                address.label.toLowerCase() == 'home'
                                    ? Icons.home_outlined
                                    : address.label.toLowerCase() == 'work'
                                        ? Icons.work_outline
                                        : Icons.location_on_outlined,
                                color: dojoOrange,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _clean(address.label).isEmpty
                                        ? _t(
                                            'Saved Address',
                                            'सेव किया गया पता',
                                            'সংরক্ষিত ঠিকানা',
                                          )
                                        : address.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: dojoText,
                                    ),
                                  ),
                                ),
                                if (address.isDefault)
                                  Text(
                                    _t('DEFAULT', 'डिफ़ॉल्ट', 'ডিফল্ট'),
                                    style: const TextStyle(
                                      color: dojoOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                _formatSavedAddress(address),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: dojoMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? dojoOrange : dojoMuted,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedSavedAddress = address;
                                _selectedAddress =
                                    _formatSavedAddress(address);
                              });
                              Navigator.of(sheetContext).pop();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openAddressForm();
                      },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(
                        _t(
                          'Add New Address',
                          'नया पता जोड़ें',
                          'নতুন ঠিকানা যোগ করুন',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dojoOrange,
                        side: const BorderSide(color: dojoOrange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0E8E0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: dojoOrange, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: dojoText,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: dojoMuted,
              height: 1.4,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: dojoMuted,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: dojoBackground,
          body: SafeArea(
            child: RefreshIndicator(
              color: dojoOrange,
              onRefresh: _loadDefaultAddress,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: dojoOrange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DOJO WALK',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: dojoText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _t(
                                'Happy walks. Happier dogs.',
                                'खुशहाल वॉक, खुशहाल डॉग्स।',
                                'আনন্দের ওয়াক, আরও খুশি কুকুর।',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: dojoMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _t(
                          'Notifications',
                          'नोटिफिकेशन',
                          'বিজ্ঞপ্তি',
                        ),
                        onPressed: () {
                          _openScreen(const NotificationsScreen());
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: dojoText,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _openAddressSelector,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFF0E8E0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: dojoOrange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t(
                                    'YOUR PICKUP LOCATION',
                                    'आपकी पिकअप लोकेशन',
                                    'আপনার পিকআপ লোকেশন',
                                  ),
                                  style: const TextStyle(
                                    color: dojoMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _loadingAddress
                                      ? _t(
                                          'Loading saved address...',
                                          'सेव किया गया पता लोड हो रहा है...',
                                          'সংরক্ষিত ঠিকানা লোড হচ্ছে...',
                                        )
                                      : _selectedAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: dojoText,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: dojoOrange,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFF0E8E0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _t(
                              'DOG WALKING SERVICE',
                              'डॉग वॉकिंग सर्विस',
                              'ডগ ওয়াকিং পরিষেবা',
                            ),
                            style: const TextStyle(
                              color: dojoOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _t(
                            'Every walk,\na happier dog.',
                            'हर वॉक,\nएक खुशहाल डॉग।',
                            'প্রতিটি ওয়াকে,\nআরও খুশি কুকুর।',
                          ),
                          style: const TextStyle(
                            color: dojoText,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _t(
                            'Book a trusted dog walk that fits your routine.',
                            'अपनी दिनचर्या के अनुसार भरोसेमंद डॉग वॉक बुक करें।',
                            'আপনার দৈনন্দিন সময় অনুযায়ী বিশ্বস্ত ডগ ওয়াক বুক করুন।',
                          ),
                          style: const TextStyle(
                            color: dojoMuted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openBooking,
                            icon: const Icon(Icons.directions_walk),
                            label: Text(
                              _t(
                                'Book a Walk',
                                'वॉक बुक करें',
                                'ওয়াক বুক করুন',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dojoOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _t('YOUR DOGS', 'आपके डॉग्स', 'আপনার কুকুর'),
                    style: const TextStyle(
                      color: dojoMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _sectionCard(
                    icon: Icons.pets,
                    title: _t('My Dogs', 'मेरे डॉग्स', 'আমার কুকুর'),
                    subtitle: _t(
                      'Manage your dogs and their saved details.',
                      'अपने डॉग्स और उनकी सेव की गई जानकारी मैनेज करें।',
                      'আপনার কুকুর এবং তাদের সংরক্ষিত তথ্য পরিচালনা করুন।',
                    ),
                    onTap: () => _openScreen(const MyDogsScreen()),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.support_agent,
                    title: _t(
                      'Help & Support',
                      'मदद और सपोर्ट',
                      'সাহায্য ও সহায়তা',
                    ),
                    subtitle: _t(
                      'Get help with bookings and dog walks.',
                      'बुकिंग और डॉग वॉक में मदद पाएँ।',
                      'বুকিং ও ডগ ওয়াকের জন্য সাহায্য পান।',
                    ),
                    onTap: () => _openScreen(const HelpSupportScreen()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
