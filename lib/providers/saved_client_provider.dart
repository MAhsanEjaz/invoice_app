import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedClientProvider extends ChangeNotifier {
  List<ClientModel> clients = [];
  int _lastId = 0;

  SavedClientProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_clients') ?? [];
    clients = data.map((e) => ClientModel.fromJson(jsonDecode(e))).toList();
    if (clients.isNotEmpty) {
      _lastId = clients.map((c) => c.id ?? 0).reduce((a, b) => a > b ? a : b);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'saved_clients',
      clients.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> addClient(ClientModel client) async {
    _lastId += 1;
    client.id = _lastId;
    clients.add(client);
    notifyListeners();
    await _persist();
  }

  Future<void> updateClient(ClientModel client) async {
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) clients[idx] = client;
    notifyListeners();
    await _persist();
  }

  Future<void> reload() => _load();

  Future<void> deleteClient(int id) async {
    clients.removeWhere((c) => c.id == id);
    notifyListeners();
    await _persist();
  }
}
