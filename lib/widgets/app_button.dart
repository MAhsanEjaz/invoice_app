import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';

class AppButton extends StatefulWidget {
  String? txt;
  Function()? onTap;

  AppButton({this.txt, this.onTap});

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: CupertinoButton(
          onPressed: (widget.onTap),
          color: buttonColor,
          child: Text(widget.txt!, style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
