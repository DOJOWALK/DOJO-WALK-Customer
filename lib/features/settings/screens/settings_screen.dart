
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/locale_controller.dart';
import '../../../app/language/language_config.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

const Color settingsOrange = DojoWalkTheme.primary;
const Color settingsBackground = DojoWalkTheme.background;
const Color settingsText = DojoWalkTheme.text;
const Color settingsMuted = DojoWalkTheme.mutedText;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final info = await PackageInfo.fromPlatform();
      final saved = prefs.getString('dojo_app_language') ?? 'en';
      final language = availableDojoLanguages.any((item) => item.code == saved)
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
        AppLocalizations.of(context).settingsLoadFailed,
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
        AppLocalizations.of(context).locationCheckFailed,
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
                AppLocalizations.of(context).chooseAppLanguage,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: settingsText,
                ),
              ),
              const SizedBox(height: 12),
              for (final language in availableDojoLanguages)
                _languageOption(
                  sheetContext,
                  language.code,
                  language.nativeName,
                ),
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
        AppLocalizations.of(context).languageSaved,
      );
    } catch (_) {
      _message(
        AppLocalizations.of(context).languageSaveFailed,
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
            ? AppLocalizations.of(context).locationPermissionDeniedMessage
            : AppLocalizations.of(context).locationPermissionUpdated,
      );
    } catch (_) {
      _message(
        AppLocalizations.of(context).openLocationSettingsFailed,
      );
    }
  }

  String get _locationStatus {
    if (_loadingLocation) {
      return AppLocalizations.of(context).checkingPermission;
    }

    if (!_locationEnabled) {
      return AppLocalizations.of(context).phoneLocationOff;
    }

    switch (_permission) {
      case LocationPermission.always:
        return AppLocalizations.of(context).permissionAlways;
      case LocationPermission.whileInUse:
        return AppLocalizations.of(context).permissionWhileUsing;
      case LocationPermission.denied:
        return AppLocalizations.of(context).permissionNotGranted;
      case LocationPermission.deniedForever:
        return AppLocalizations.of(context).permissionBlocked;
      case LocationPermission.unableToDetermine:
      case null:
        return AppLocalizations.of(context).statusUnavailable;
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
        title: Text(
          AppLocalizations.of(context).settingsTitle,
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
              borderRadius: BorderRadius.circular(22),
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
                  AppLocalizations.of(context).appPreferences,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppLocalizations.of(context).settingsIntro,
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
            AppLocalizations.of(context).appSettingsSection,
          ),
          _settingsTile(
            icon: Icons.language_rounded,
            title: AppLocalizations.of(context).appLanguage,
            subtitle: dojoLanguageByCode(_language).nativeName,
            onTap: _chooseLanguage,
          ),
          _settingsTile(
            icon: Icons.location_on_outlined,
            title: AppLocalizations.of(context).locationPermission,
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
            title: AppLocalizations.of(context).appVersion,
            subtitle: _appVersion,
            showArrow: false,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              AppLocalizations.of(context).customerAppFooter,
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
