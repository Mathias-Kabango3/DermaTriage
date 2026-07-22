import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's selected language and persists it across launches.
///
/// Defaults to English. Supported: `en`, `rw` (Kinyarwanda).
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isKinyarwanda => _locale.languageCode == 'rw';

  /// Load the saved language. Call once before the app renders.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_prefsKey);
    if (code == 'en' || code == 'rw') {
      _locale = Locale(code!);
    }
  }

  /// Switch language and persist the choice.
  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
