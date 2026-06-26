import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/models/service_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceProvider extends ChangeNotifier {
  List<ServiceModel> services = [];
  int _lastId = 0;

  ServiceProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('services') ?? [];
    services = data
        .map((e) => ServiceModel.fromJson(jsonDecode(e)))
        .toList();
    if (services.isNotEmpty) {
      _lastId = services
          .map((s) => s.id ?? 0)
          .reduce((a, b) => a > b ? a : b);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'services',
      services.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<void> addService(ServiceModel service) async {
    _lastId += 1;
    service.id = _lastId;
    services.add(service);
    notifyListeners();
    await _persist();
  }

  Future<void> updateService(ServiceModel service) async {
    final idx = services.indexWhere((s) => s.id == service.id);
    if (idx >= 0) services[idx] = service;
    notifyListeners();
    await _persist();
  }

  Future<void> reload() => _load();

  Future<void> deleteService(int id) async {
    services.removeWhere((s) => s.id == id);
    notifyListeners();
    await _persist();
  }
}
