import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceNumberProvider extends ChangeNotifier {
  String _prefix = '';
  bool _includeYear = false;
  int _padLength = 1;

  String get prefix => _prefix;
  bool get includeYear => _includeYear;
  int get padLength => _padLength;
  bool get isCustom => _prefix.isNotEmpty || _includeYear || _padLength > 1;

  InvoiceNumberProvider() {
    _load();
  }

  /// Returns a formatted invoice number string, e.g. "INV-2024-042".
  /// When no custom format is set, returns the plain number string.
  String format(int id) {
    final padded = id.toString().padLeft(_padLength.clamp(1, 9), '0');
    if (_prefix.isEmpty && !_includeYear) return padded;
    if (_includeYear) {
      return '$_prefix${DateTime.now().year}-$padded';
    }
    return '$_prefix$padded';
  }

  /// Preview string for settings UI, using a sample id of 1.
  String get preview => format(1);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefix = prefs.getString('inv_num_prefix') ?? '';
    _includeYear = prefs.getBool('inv_num_year') ?? false;
    _padLength = prefs.getInt('inv_num_pad') ?? 1;
    notifyListeners();
  }

  Future<void> reload() => _load();

  Future<void> update({
    required String prefix,
    required bool includeYear,
    required int padLength,
  }) async {
    _prefix = prefix.trim();
    _includeYear = includeYear;
    _padLength = padLength.clamp(1, 9);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inv_num_prefix', _prefix);
    await prefs.setBool('inv_num_year', _includeYear);
    await prefs.setInt('inv_num_pad', _padLength);
    notifyListeners();
  }
}
