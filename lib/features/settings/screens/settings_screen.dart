
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/app_language.dart';

const Color settingsOrange = Color(0xFFFF7900);
const Color settingsBackground = Color(0xFFFFFAF5);
const Color settingsText = Color(0xFF202020);
const Color settingsMuted = Color(0xFF777777);
const Color settingsWarmBorder = Color(0xFFFFE1C8);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  String _language = 'en';
  String _appVersion = 'Loading...';

  LocationPermission? _permission;
  bool _locationEnabled = false;
  bool _loadingLocation = true;

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
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocation();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final info = await PackageInfo.fromPlatform();
      final saved = prefs.getString('dojo_app_language') ?? 'en';
      final language = ['en', 'hi', 'bn'].contains(saved)
          ? saved
          : 'en';

      if (!mounted) return;

      setState(() {
        _language = language;
        _appVersion = '${info.version}+${info.buildNumber}';
      });

      appLocale.value = Locale(language);
      await _checkLocation();
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'Unavailable');
      _message(
        _t(
          'Could not load app settings.',
          'ऐप सेटिंग लोड नहीं हो सकीं।',
          'অ্যাপের সেটিংস লোড করা যায়নি।',
        ),
      );
    }
  }

  Future<void> _checkLocation() async {
    if (mounted) {
      setState(() => _loadingLocation = true);
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      if (!mounted) return;

      setState(() {
        _locationEnabled = enabled;
        _permission = permission;
        _loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loadingLocation = false);
      _message(
        _t(
          'Could not check location status.',
          'लोकेशन की स्थिति जाँची नहीं जा सकी।',
          'লোকেশনের অবস্থা যাচাই করা যায়নি।',
        ),
      );
    }
  }

  Future<void> _chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: settingsBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(
                  'Choose App Language',
                  'ऐप की भाषा चुनें',
                  'অ্যাপের ভাষা বেছে নিন',
                ),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: settingsText,
                ),
              ),
              const SizedBox(height: 12),
              _languageOption(sheetContext, 'en', 'English'),
              _languageOption(sheetContext, 'hi', 'हिन्दी'),
              _languageOption(sheetContext, 'bn', 'বাংলা'),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dojo_app_language', selected);

      if (!mounted) return;

      setState(() => _language = selected);
      appLocale.value = Locale(selected);

      _message(
        _t(
          'Language preference saved.',
          'भाषा की पसंद सेव हो गई।',
          'ভাষার পছন্দ সংরক্ষণ করা হয়েছে।',
        ),
      );
    } catch (_) {
      _message(
        _t(
          'Could not save language preference.',
          'भाषा सेव नहीं हो सकी।',
          'ভাষার পছন্দ সংরক্ষণ করা যায়নি।',
        ),
      );
    }
  }

  Widget _languageOption(
    BuildContext sheetContext,
    String code,
    String label,
  ) {
    final selected = _language == code;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        color: settingsOrange,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: settingsText,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => Navigator.pop(sheetContext, code),
    );
  }

  Future<void> _manageLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      await _checkLocation();

      _message(
        permission == LocationPermission.denied
            ? _t(
                'Location permission has not been granted.',
                'लोकेशन की अनुमति नहीं मिली।',
                'লোকেশনের অনুমতি দেওয়া হয়নি।',
              )
            : _t(
                'Location permission status updated.',
                'लोकेशन अनुमति की स्थिति अपडेट हुई।',
                'লোকেশনের অনুমতির অবস্থা আপডেট হয়েছে।',
              ),
      );
    } catch (_) {
      _message(
        _t(
          'Could not open location settings.',
          'लोकेशन सेटिंग नहीं खुल सकीं।',
          'লোকেশন সেটিংস খোলা যায়নি।',
        ),
      );
    }
  }

  String get _locationStatus {
    if (_loadingLocation) {
      return _t(
        'Checking permission...',
        'अनुमति जाँची जा रही है...',
        'অনুমতি যাচাই করা হচ্ছে...',
      );
    }

    if (!_locationEnabled) {
      return _t(
        'Phone location is turned off',
        'फोन की लोकेशन बंद है',
        'ফোনের লোকেশন বন্ধ আছে',
      );
    }

    switch (_permission) {
      case LocationPermission.always:
        return _t(
          'Allowed all the time',
          'हर समय अनुमति है',
          'সব সময় অনুমতি দেওয়া আছে',
        );
      case LocationPermission.whileInUse:
        return _t(
          'Allowed while using the app',
          'ऐप इस्तेमाल करते समय अनुमति है',
          'অ্যাপ ব্যবহার করার সময় অনুমতি আছে',
        );
      case LocationPermission.denied:
        return _t(
          'Permission not granted',
          'अनुमति नहीं मिली',
          'অনুমতি দেওয়া হয়নি',
        );
      case LocationPermission.deniedForever:
        return _t(
          'Permission blocked in phone settings',
          'फोन सेटिंग में अनुमति ब्लॉक है',
          'ফোনের সেটিংসে অনুমতি বন্ধ করা আছে',
        );
      case LocationPermission.unableToDetermine:
      case null:
        return _t(
          'Status unavailable',
          'स्थिति उपलब्ध नहीं है',
          'অবস্থা পাওয়া যাচ্ছে না',
        );
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: settingsBackground,
      appBar: AppBar(
        backgroundColor: settingsBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: settingsText),
        title: Text(
          _t('Settings', 'सेटिंग्स', 'সেটিংস'),
          style: const TextStyle(
            color: settingsText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [settingsOrange, Color(0xFFFFA34D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: settingsOrange.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  _t(
                    'App Preferences',
                    'ऐप की प्राथमिकताएँ',
                    'অ্যাপের পছন্দসমূহ',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _t(
                    'Customize your DOJO WALK experience.',
                    'अपने DOJO WALK अनुभव को अपनी पसंद के अनुसार बनाएँ।',
                    'আপনার পছন্দ অনুযায়ী DOJO WALK ব্যবহার করুন।',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _sectionTitle(
            _t('APP SETTINGS', 'ऐप सेटिंग्स', 'অ্যাপ সেটিংস'),
          ),
          _settingsTile(
            icon: Icons.language_rounded,
            title: _t('App Language', 'ऐप की भाषा', 'অ্যাপের ভাষা'),
            subtitle: switch (_language) {
              'hi' => 'हिन्दी',
              'bn' => 'বাংলা',
              _ => 'English',
            },
            onTap: _chooseLanguage,
          ),
          _settingsTile(
            icon: Icons.location_on_outlined,
            title: _t(
              'Location Permission',
              'लोकेशन अनुमति',
              'লোকেশনের অনুমতি',
            ),
            subtitle: _locationStatus,
            onTap: _manageLocation,
          ),
          const SizedBox(height: 18),
          _sectionTitle(
            _t(
              'APP INFORMATION',
              'ऐप की जानकारी',
              'অ্যাপের তথ্য',
            ),
          ),
          _settingsTile(
            icon: Icons.info_outline_rounded,
            title: _t('App Version', 'ऐप संस्करण', 'অ্যাপের সংস্করণ'),
            subtitle: _appVersion,
            showArrow: false,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _t(
                'DOJO WALK • Customer App',
                'DOJO WALK • ग्राहक ऐप',
                'DOJO WALK • গ্রাহক অ্যাপ',
              ),
              style: const TextStyle(
                color: settingsMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
          color: settingsMuted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFFF7EF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: settingsWarmBorder),
        boxShadow: [
          BoxShadow(
            color: settingsOrange.withValues(alpha: 0.08),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 7,
        ),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E3),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: settingsOrange, size: 23),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: settingsText,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: settingsMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        trailing: showArrow
            ? const Icon(
                Icons.chevron_right_rounded,
                color: settingsMuted,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
