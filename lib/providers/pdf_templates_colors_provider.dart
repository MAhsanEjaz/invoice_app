import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InvoiceTemplate { classic, elegant, minimal, wave, boutique, geometric }

extension InvoiceTemplateX on InvoiceTemplate {
  String get label {
    switch (this) {
      case InvoiceTemplate.classic:
        return 'Classic';
      case InvoiceTemplate.elegant:
        return 'Elegant';
      case InvoiceTemplate.minimal:
        return 'Minimal';
      case InvoiceTemplate.wave:
        return 'Wave';
      case InvoiceTemplate.boutique:
        return 'Boutique';
      case InvoiceTemplate.geometric:
        return 'Geometric';
    }
  }

  String get description {
    switch (this) {
      case InvoiceTemplate.classic:
        return 'Bold colored header';
      case InvoiceTemplate.elegant:
        return 'Dark premium look';
      case InvoiceTemplate.minimal:
        return 'Clean & airy';
      case InvoiceTemplate.wave:
        return 'Curved wave header';
      case InvoiceTemplate.boutique:
        return 'Editorial · clean';
      case InvoiceTemplate.geometric:
        return 'Dual-color corners';
    }
  }
}

class TemplatesColorsProvider extends ChangeNotifier {
  Color color = const Color(0xFF0D7377);
  String colorCode = 'FF0D7377';
  InvoiceTemplate template = InvoiceTemplate.classic;

  TemplatesColorsProvider() {
    load();
  }

  final List<Color> colors = const [
    Color(0xFF0D7377), // Teal (default)
    Color(0xFF1E40AF), // Indigo
    Color(0xFF7C3AED), // Purple
    Color(0xFFBE185D), // Pink
    Color(0xFF065F46), // Emerald
    Color(0xFF92400E), // Amber
    Color(0xFF1F2937), // Charcoal
    Color(0xFFDC2626), // Red
    Color(0xFF0369A1), // Sky Blue
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hex = prefs.getString('pref_invoice_color');
    if (hex != null) {
      final val = int.tryParse(hex, radix: 16);
      if (val != null) color = Color(val);
      colorCode = hex;
    }
    final tIdx = prefs.getInt('pref_invoice_template') ?? 0;
    template = InvoiceTemplate.values[tIdx.clamp(0, InvoiceTemplate.values.length - 1)];
    notifyListeners();
  }

  void selectColor(Color selection) {
    color = selection;
    colorCode = selection.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    _persist();
    notifyListeners();
  }

  void selectTemplate(InvoiceTemplate t) {
    template = t;
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_invoice_color', colorCode);
    await prefs.setInt('pref_invoice_template', template.index);
  }
}
