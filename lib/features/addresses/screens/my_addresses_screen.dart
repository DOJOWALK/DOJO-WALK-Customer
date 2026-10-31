import '../../../app/theme.dart';
import '../../../app/locale_controller.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/saved_address.dart';
import '../services/address_service.dart';
import 'address_form_screen.dart';

const Color addressOrange = DojoWalkTheme.primary;
const Color addressBackground = DojoWalkTheme.background;
const Color addressText = DojoWalkTheme.text;
const Color addressMuted = DojoWalkTheme.mutedText;

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  @override
  void initState() {
    super.initState();
    appLocale.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    appLocale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  String _text(String en, String hi, String bn) =>
      appText(en: en, hi: hi, bn: bn);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: addressBackground,
        appBar: AppBar(
          backgroundColor: addressBackground,
          title: Text(_text('Saved Addresses', 'सेव किए गए पते', 'সংরক্ষিত ঠিকানা')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _text('Please sign in to manage your saved addresses.', 'सेव किए गए पते देखने के लिए लॉग इन करें।', 'সংরক্ষিত ঠিকানা পরিচালনা করতে সাইন ইন করুন.'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final service = AddressService();

    return Scaffold(
      backgroundColor: addressBackground,
      appBar: AppBar(
        backgroundColor: addressBackground,
        elevation: 0,
        title: Text(
          _text('Saved Addresses', 'सेव किए गए पते', 'সংরক্ষিত ঠিকানা'),
          style: TextStyle(
            color: addressText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<List<SavedAddress>>(
        stream: service.watchAddresses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _centerMessage(
              _text('Could not load addresses. Check your connection and try again.', 'पते लोड नहीं हो सके। इंटरनेट जाँचकर फिर कोशिश करें।', 'ঠিকানা লোড করা যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন.'),
              retry: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyAddressesScreen(),
                  ),
                );
              },
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: addressOrange,
              ),
            );
          }

          final addresses = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAD8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: addressOrange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _text('Save your pickup locations for faster dog-walk bookings.', 'तेज़ बुकिंग के लिए अपने पिकअप पते सेव करें।', 'দ্রুত বুকিংয়ের জন্য পিকআপের ঠিকানা সংরক্ষণ করুন.'),
                        style: TextStyle(
                          color: addressText,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (addresses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_searching_rounded,
                        size: 48,
                        color: addressOrange,
                      ),
                      SizedBox(height: 14),
                      Text(
                        _text('No saved addresses yet', 'अभी कोई पता सेव नहीं है', 'এখনও কোনো ঠিকানা সংরক্ষিত নেই'),
                        style: TextStyle(
                          color: addressText,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        _text('Add your home or another pickup location.', 'अपने घर या किसी अन्य पिकअप की जगह का पता जोड़ें।', 'বাড়ি বা অন্য পিকআপের ঠিকানা যোগ করুন.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: addressMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...addresses.map(
                  (address) => _addressCard(
                    context,
                    service,
                    address,
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: addressOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: Text(
              _text('Add New Address', 'नया पता जोड़ें', 'নতুন ঠিকানা যোগ করুন'),
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressCard(
    BuildContext context,
    AddressService service,
    SavedAddress address,
  ) {
    final details = [
      address.flatHouse,
      address.buildingSociety,
      address.area,
      address.landmark,
      address.city,
      address.pincode,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: address.isDefault
              ? addressOrange.withValues(alpha: 0.55)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  address.label == 'Home'
                      ? Icons.home_rounded
                      : address.label == 'Work'
                          ? Icons.work_outline_rounded
                          : Icons.location_on_outlined,
                  color: addressOrange,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  address.label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: addressText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAD8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _text('DEFAULT', 'डिफ़ॉल्ट', 'ডিফল্ট'),
                    style: TextStyle(
                      color: addressOrange,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            details.isEmpty ? _text('Address details not available', 'पते का विवरण उपलब्ध नहीं है', 'ঠিকানার বিবরণ পাওয়া যায়নি') : details,
            style: const TextStyle(
              color: addressText,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          if (address.pickupInstructions.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              '${_text('Pickup instructions', 'पिकअप निर्देश', 'পিকআপের নির্দেশনা')}: ${address.pickupInstructions}',
              style: const TextStyle(
                color: addressMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const Divider(height: 25),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (!address.isDefault)
                TextButton.icon(
                  onPressed: () => _setDefault(
                    context,
                    service,
                    address,
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(_text('Set Default', 'डिफ़ॉल्ट बनाएँ', 'ডিফল্ট করুন')),
                ),
              TextButton.icon(
                onPressed: () => _openForm(
                  context,
                  address: address,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(_text('Edit', 'बदलें', 'সম্পাদনা')),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(
                  context,
                  service,
                  address,
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(_text('Delete', 'हटाएँ', 'মুছুন')),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    SavedAddress? address,
  }) async {
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => AddressFormScreen(address: address),
        ),
      );

      if (!context.mounted || result == null) return;

      _showMessage(
        context,
        address == null
            ? _text('Address saved successfully.', 'पता सेव हो गया।', 'ঠিকানা সংরক্ষণ করা হয়েছে.')
            : _text('Address updated successfully.', 'पता अपडेट हो गया।', 'ঠিকানা আপডেট করা হয়েছে.'),
      );
    } catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          _text('Could not save address. Please try again.', 'पता सेव नहीं हो सका। दोबारा कोशिश करें।', 'ঠিকানা সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন.'),
        );
      }
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    AddressService service,
    SavedAddress address,
  ) async {
    try {
      await service.setDefaultAddress(address.id);

      if (context.mounted) {
        _showMessage(context, _text('${address.label} set as default.', '${address.label} डिफ़ॉल्ट पता बन गया।', '${address.label} ডিফল্ট ঠিকানা হয়েছে.'));
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          _text('Could not update default address. Please try again.', 'डिफ़ॉल्ट पता अपडेट नहीं हुआ। दोबारा कोशिश करें।', 'ডিফল্ট ঠিকানা আপডেট করা যায়নি। আবার চেষ্টা করুন.'),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AddressService service,
    SavedAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_text('Delete address?', 'पता हटाएँ?', 'ঠিকানা মুছবেন?')),
        content: Text(
          _text('This saved address will be removed from your account. Existing bookings will not be changed.', 'यह पता आपके खाते से हट जाएगा। मौजूदा बुकिंग पर इसका असर नहीं पड़ेगा।', 'এই ঠিকানাটি আপনার অ্যাকাউন্ট থেকে মুছে যাবে। আগের বুকিং বদলাবে না.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_text('Keep Address', 'पता रहने दें', 'ঠিকানা রাখুন')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_text('Delete', 'हटाएँ', 'মুছুন')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await service.deleteAddress(address.id);

      if (context.mounted) {
        _showMessage(context, _text('Address deleted.', 'पता हटा दिया गया।', 'ঠিকানা মুছে ফেলা হয়েছে.'));
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          _text('Could not delete address. Please try again.', 'पता हटाया नहीं जा सका। दोबारा कोशिश करें।', 'ঠিকানা মুছে ফেলা যায়নি। আবার চেষ্টা করুন.'),
        );
      }
    }
  }
}

Widget _centerMessage(
  String message, {
  VoidCallback? retry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: addressMuted,
              height: 1.5,
            ),
          ),
          if (retry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: retry,
              child: Text(appText(en: 'Retry', hi: 'फिर कोशिश करें', bn: 'আবার চেষ্টা করুন')),
            ),
          ],
        ],
      ),
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
