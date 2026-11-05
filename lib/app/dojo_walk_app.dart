import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../features/splash/screens/splash_screen.dart';
import 'theme.dart';
import 'locale_controller.dart';

class DojoWalkApp extends StatelessWidget {
  const DojoWalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'DOJO WALK',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: DojoWalkTheme.light(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
