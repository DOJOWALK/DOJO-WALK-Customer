import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'locale_controller.dart';
import '../features/splash/screens/splash_screen.dart';
import 'theme.dart';

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

          supportedLocales: dojoSupportedLocales,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: DojoWalkTheme.light(),

          home: const SplashScreen(),
        );
      },
    );
  }
}
