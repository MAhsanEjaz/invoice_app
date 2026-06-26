import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/models/bank_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BankProvider extends ChangeNotifier {
  List<BankModel> banks = [];
  int _lastId = 0;

  BankProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('bank_accounts') ?? [];
    banks = data.map((e) => BankModel.fromJson(jsonDecode(e))).toList();
    if (banks.isNotEmpty) {
      _lastId = banks.map((b) => b.id ?? 0).reduce((a, b) => a > b ? a : b);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'bank_accounts',
      banks.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  Future<void> addBank(BankModel bank) async {
    _lastId += 1;
    bank.id = _lastId;
    banks.add(bank);
    notifyListeners();
    await _persist();
  }

  Future<void> updateBank(BankModel bank) async {
    final idx = banks.indexWhere((b) => b.id == bank.id);
    if (idx >= 0) banks[idx] = bank;
    notifyListeners();
    await _persist();
  }

  Future<void> reload() => _load();

  Future<void> deleteBank(int id) async {
    banks.removeWhere((b) => b.id == id);
    notifyListeners();
    await _persist();
  }
}
