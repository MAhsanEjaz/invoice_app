import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> reload() => _load();

  Future<void> setLocale(String code) async {
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', code);
    notifyListeners();
  }
}
