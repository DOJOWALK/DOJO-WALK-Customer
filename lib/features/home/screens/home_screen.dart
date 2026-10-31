
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
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
  const HomeScreen({
    super.key,
    this.isSignedIn,
    this.loadAddresses,
  });

  /// Optional seams for deterministic retry tests; production uses Firebase.
  final bool Function()? isSignedIn;
  final Future<List<SavedAddress>> Function()? loadAddresses;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AddressService _addressService = AddressService();

  bool get _isSignedIn =>
      widget.isSignedIn?.call() ?? FirebaseAuth.instance.currentUser != null;

  Future<List<SavedAddress>> _loadAddresses() =>
      widget.loadAddresses?.call() ?? _addressService.getAddresses();

  SavedAddress? _selectedSavedAddress;
  String _selectedAddress = 'Select your location';
  bool _loadingAddress = true;
  bool _addressLoadFailed = false;


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

  String _formatSavedAddress(BuildContext context, SavedAddress address) {
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
          ? AppLocalizations.of(context).homeSavedAddress
          : label;
    }

    final label = _clean(address.label);
    final details = parts.join(', ');
    return label.isEmpty ? details : '$label · $details';
  }

  Future<void> _loadDefaultAddress() async {
    if (mounted) {
      setState(() {
        _loadingAddress = true;
        _addressLoadFailed = false;
      });
    }

    if (!_isSignedIn) {
      if (mounted) {
        setState(() {
          _loadingAddress = false;
          _addressLoadFailed = false;
        });
      }
      return;
    }

    try {
      final addresses = await _loadAddresses();

      if (!mounted) return;

      if (addresses.isEmpty) {
        setState(() {
          _selectedSavedAddress = null;
          _selectedAddress = AppLocalizations.of(context).homeSelectLocation;
          _loadingAddress = false;
          _addressLoadFailed = false;
        });
        return;
      }

      final SavedAddress selected = addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => addresses.first,
      );

      setState(() {
        _selectedSavedAddress = selected;
        _selectedAddress = _formatSavedAddress(context, selected);
        _loadingAddress = false;
        _addressLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAddress = false;
        _addressLoadFailed = true;
      });
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
    if (!_isSignedIn) {
      _showMessage(
        AppLocalizations.of(context).homeLoginManageAddresses,
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
    if (!_isSignedIn) {
      _showMessage(
        AppLocalizations.of(context).homeLoginSelectAddress,
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
                          AppLocalizations.of(context).homeChoosePickupAddress,
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
                              AppLocalizations.of(context).homeAddressesLoadError,
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
                                  AppLocalizations.of(context).homeNoSavedAddresses,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: dojoText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppLocalizations.of(context).homeAddAddressForPickup,
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
                                        ? AppLocalizations.of(context).homeSavedAddress
                                        : address.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: dojoText,
                                    ),
                                  ),
                                ),
                                if (address.isDefault)
                                  Text(
                                    AppLocalizations.of(context).homeDefaultAddress,
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
                                _formatSavedAddress(context, address),
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
                                    _formatSavedAddress(context, address);
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
                        AppLocalizations.of(context).homeAddNewAddress,
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
                              AppLocalizations.of(context).homeTagline,
                              style: const TextStyle(
                                fontSize: 12,
                                color: dojoMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: AppLocalizations.of(context).homeNotifications,
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
                                  AppLocalizations.of(context).homePickupLocationLabel,
                                  style: const TextStyle(
                                    color: dojoMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _loadingAddress && _selectedSavedAddress == null
                                      ? AppLocalizations.of(context).homeLoadingSavedAddress
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
                  if (_addressLoadFailed) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).homeSavedAddressLoadError,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _loadDefaultAddress,
                          icon: const Icon(Icons.refresh_rounded, size: 17),
                          label: Text(AppLocalizations.of(context).retry),
                          style: TextButton.styleFrom(foregroundColor: dojoOrange),
                        ),
                      ],
                    ),
                  ],
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
                            AppLocalizations.of(context).homeDogWalkingService,
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
                          AppLocalizations.of(context).homeHeroTitle,
                          style: const TextStyle(
                            color: dojoText,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context).homeHeroSubtitle,
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
                              AppLocalizations.of(context).homeBookWalk,
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
                    AppLocalizations.of(context).homeYourDogs,
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
                    title: AppLocalizations.of(context).homeMyDogs,
                    subtitle: AppLocalizations.of(context).homeManageDogsSubtitle,
                    onTap: () => _openScreen(const MyDogsScreen()),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: Icons.support_agent,
                    title: AppLocalizations.of(context).homeHelpSupport,
                    subtitle: AppLocalizations.of(context).homeHelpSupportSubtitle,
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
