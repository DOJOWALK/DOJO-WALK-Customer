
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/locale_controller.dart';
import 'app/language/language_config.dart';
import 'app/dojo_walk_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage =
      prefs.getString('dojo_app_language') ?? 'en';

  final supportedLanguages = availableDojoLanguages
      .map((language) => language.code)
      .toSet();

  final languageCode = supportedLanguages.contains(savedLanguage)
      ? savedLanguage
      : 'en';

  appLocale.value = Locale(languageCode);

  runApp(const DojoWalkApp());
}
