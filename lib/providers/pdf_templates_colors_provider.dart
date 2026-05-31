import 'package:flutter/material.dart';

class TemplatesColorsProvider extends ChangeNotifier {
  Color? color;

  String? colorCode;

  List<Color> colors = [
    Color(0xff36d782),
    Color(0xffa7b63d),
    Color(0xff9685d7),
    Color(0x96d32e8a),
    Color(0xdd354385),
    Color(0xdbec5b3a),
    Color(0xca4beee4),
    Color(0xff091d80),
    Color(0xff4d0f2c),
  ];

  selectColor(Color selection) {
    color = selection;

    final hexCode = selection.value.toRadixString(16).padLeft(8, '0');

    colorCode = hexCode;
    print('colorCode ---> 0x$hexCode');
    notifyListeners();
  }
}
