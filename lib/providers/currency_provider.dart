import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/models/currency_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  static const _key = 'selected_currency';

  CurrencyModel _currency = CurrencyModel.defaultCurrency;

  CurrencyModel get currency => _currency;
  String get symbol => _currency.symbol;
  String get code => _currency.code;

  CurrencyProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _currency = CurrencyModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        notifyListeners();
      } catch (e) {
        debugPrint('CurrencyProvider: failed to parse saved currency — $e');
      }
    }
  }

  Future<void> select(CurrencyModel currency) async {
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(currency.toJson()));
    notifyListeners();
  }
}
