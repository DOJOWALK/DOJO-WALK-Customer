
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color settingsOrange = Color(0xFFFF7900);
const Color settingsBackground = Color(0xFFFFFAF5);
const Color settingsText = Color(0xFF202020);
const Color settingsMuted = Color(0xFF777777);

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
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      _language = prefs.getString('dojo_app_language') ?? 'en';
      _appVersion = '${info.version}+${info.buildNumber}';
    });

    await _checkLocation();
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
      setState(() {
        _loadingLocation = false;
      });
      _message('Could not check location status.');
    }
  }

  Future<void> _chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: settingsBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose App Language',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: settingsText,
                ),
              ),
              const SizedBox(height: 12),
              _languageOption(context, 'en', 'English'),
              _languageOption(context, 'hi', 'हिंदी'),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dojo_app_language', selected);

    if (!mounted) return;
    setState(() => _language = selected);

    _message(
      selected == 'hi'
          ? 'भाषा की पसंद सेव हो गई।'
          : 'Language preference saved.',
    );
  }

  Widget _languageOption(
    BuildContext context,
    String code,
    String label,
  ) {
    final selected = _language == code;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: settingsOrange,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: settingsText,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => Navigator.pop(context, code),
    );
  }

  Future<void> _manageLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        final opened = await Geolocator.openLocationSettings();
        if (!opened) await Geolocator.openAppSettings();
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

      if (permission == LocationPermission.denied) {
        _message('Location permission has not been granted.');
      } else {
        _message('Location permission status updated.');
      }
    } catch (_) {
      _message('Could not open location settings.');
    }
  }

  String get _locationStatus {
    if (_loadingLocation) return 'Checking permission...';

    if (!_locationEnabled) return 'Phone location is turned off';

    switch (_permission) {
      case LocationPermission.always:
        return 'Allowed all the time';
      case LocationPermission.whileInUse:
        return 'Allowed while using the app';
      case LocationPermission.denied:
        return 'Permission not granted';
      case LocationPermission.deniedForever:
        return 'Permission blocked in phone settings';
      case LocationPermission.unableToDetermine:
      case null:
        return 'Status unavailable';
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
        iconTheme: const IconThemeData(color: settingsText),
        title: const Text(
          'Settings',
          style: TextStyle(
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
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(height: 12),
                Text(
                  'App Preferences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Customize your DOJO WALK experience.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _sectionTitle('APP SETTINGS'),
          _settingsTile(
            icon: Icons.language_rounded,
            title: 'App Language',
            subtitle: _language == 'hi' ? 'हिंदी' : 'English',
            onTap: _chooseLanguage,
          ),
          _settingsTile(
            icon: Icons.location_on_outlined,
            title: 'Location Permission',
            subtitle: _locationStatus,
            onTap: _manageLocation,
          ),
          const SizedBox(height: 18),
          _sectionTitle('APP INFORMATION'),
          _settingsTile(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle: _appVersion,
            showArrow: false,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'DOJO WALK • Customer App',
              style: TextStyle(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF0ECE8)),
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
