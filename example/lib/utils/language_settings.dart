import 'package:flutter/material.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettings {
  static const system = 'system';
  static const _key = 'language';
  static final selected = ValueNotifier<String>(system);

  static void load(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    selected.value = AppLocalizations.supportedLocales.any((locale) => locale.languageCode == value) ? value! : system;
  }

  static Future<void> save(String value) async {
    selected.value = value;
    await (await SharedPreferences.getInstance()).setString(_key, value);
  }
}
