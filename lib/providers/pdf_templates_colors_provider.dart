import 'package:flutter/material.dart';

class TemplatesColorsProvider extends ChangeNotifier {
  // Default to app primary teal so PDF never crashes on null
  Color color = const Color(0xFF0D7377);
  String colorCode = 'FF0D7377';

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

  void selectColor(Color selection) {
    color = selection;
    colorCode = selection.toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    notifyListeners();
  }
}
