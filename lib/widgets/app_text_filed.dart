import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';

class AppTextFiled extends StatefulWidget {
  final TextEditingController controller;
  final String? placeholder;
  TextInputType?textInputType;

  Function(String val)? onChanged;

  AppTextFiled({super.key, required this.controller, this.placeholder, this.onChanged,this.textInputType});

  @override
  State<AppTextFiled> createState() => _AppTextFiledState();
}

class _AppTextFiledState extends State<AppTextFiled> {
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode!.addListener(() {
      setState(() {}); // Rebuild on focus change to update border
    });
  }

  @override
  void dispose() {
    _focusNode!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: CupertinoTextField(
        onChanged: (widget.onChanged),
        focusNode: _focusNode,
        keyboardType:widget.textInputType ,
        autofocus: true,
        clearButtonMode: OverlayVisibilityMode.editing,
        autocorrect: true,
        placeholderStyle: TextStyle(color: Colors.black87),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.6),
          border: Border.all(
            color: _focusNode!.hasFocus ? buttonColor : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        controller: widget.controller,
        placeholder: widget.placeholder,
      ),
    );
  }
}
