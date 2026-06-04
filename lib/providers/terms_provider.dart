import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsProvider extends ChangeNotifier {
  static const _key = 'terms_conditions';
  String _terms = '';

  String get terms => _terms;
  bool get hasTerms => _terms.trim().isNotEmpty;

  TermsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _terms = prefs.getString(_key) ?? '';
    notifyListeners();
  }

  Future<void> save(String text) async {
    _terms = text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _terms);
    notifyListeners();
  }
}
