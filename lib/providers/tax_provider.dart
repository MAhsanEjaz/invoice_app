import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaxProvider extends ChangeNotifier {
  double _rate = 0.0;
  String _label = 'Tax';

  double get rate => _rate;
  String get label => _label;
  bool get hasTax => _rate > 0;

  TaxProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _rate = prefs.getDouble('tax_default_rate') ?? 0.0;
    _label = prefs.getString('tax_default_label') ?? 'Tax';
    notifyListeners();
  }

  Future<void> reload() => _load();

  Future<void> update(double rate, String label) async {
    _rate = rate.clamp(0.0, 100.0);
    _label = label.trim().isEmpty ? 'Tax' : label.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tax_default_rate', _rate);
    await prefs.setString('tax_default_label', _label);
    notifyListeners();
  }
}
