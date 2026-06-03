import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';

class AppTextFiled extends StatefulWidget {
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? textInputType;
  final Function(String val)? onChanged;
  final bool autofocus;

  const AppTextFiled({
    super.key,
    required this.controller,
    this.placeholder,
    this.onChanged,
    this.textInputType,
    this.autofocus = false,
  });

  @override
  State<AppTextFiled> createState() => _AppTextFiledState();
}

class _AppTextFiledState extends State<AppTextFiled> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      keyboardType: widget.textInputType,
      autofocus: widget.autofocus,
      clearButtonMode: OverlayVisibilityMode.editing,
      autocorrect: false,
      style: GoogleFonts.poppins(fontSize: 15, color: kTextPrimary),
      placeholderStyle: GoogleFonts.poppins(fontSize: 15, color: kTextHint),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(
          color: _focusNode.hasFocus ? kPrimary : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      controller: widget.controller,
      placeholder: widget.placeholder,
    );
  }
}
