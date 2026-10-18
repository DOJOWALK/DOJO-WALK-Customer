import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_language.dart';
import 'theme.dart';
import '../features/splash/screens/splash_screen.dart';

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

          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('bn'),
          ],

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
