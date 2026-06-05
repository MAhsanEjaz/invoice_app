import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';

import '../services/navigations.dart';
import 'invoice_dummy.dart' show InvoiceDummy;

class BusinessStartPage extends StatefulWidget {
  const BusinessStartPage({super.key});

  @override
  State<BusinessStartPage> createState() => _BusinessStartPageState();
}

class _BusinessStartPageState extends State<BusinessStartPage> {
  final TextEditingController _nameCont = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasInput = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _nameCont.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final topPad = MediaQuery.of(context).padding.top;

    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: kPrimary,
          body: Stack(
            children: [
              Positioned(top: -80, right: -80, child: _circle(240, 0.08)),
              Positioned(top: 80, left: -100, child: _circle(200, 0.05)),
              Positioned(
                top: 0, left: 0, right: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, topPad + 36, 28, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Icon(CupertinoIcons.doc_text_fill, color: Colors.white, size: 28),
                    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.easeOut),
                    const SizedBox(height: 22),
                    Text('Set up your\nbusiness', style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, height: 1.15, letterSpacing: -0.5))
                        .animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.2, end: 0, delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: 10),
                    Text('Just one step to start\ncreating professional invoices.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.72), height: 1.5))
                        .animate().fadeIn(delay: 250.ms, duration: 400.ms),
                  ]),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                bottom: viewInsets.bottom, left: 0, right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: cl.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -6))],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(color: cl.border, borderRadius: BorderRadius.circular(2)))),
                        sectionLabel(context, 'Your business name'),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: cl.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _isFocused ? kPrimary : Colors.transparent, width: 1.5),
                          ),
                          child: CupertinoTextField(
                            controller: _nameCont,
                            focusNode: _focusNode,
                            autofocus: false,
                            placeholder: 'e.g. Acme Studio',
                            placeholderStyle: GoogleFonts.poppins(fontSize: 15, color: cl.textHint),
                            style: GoogleFonts.poppins(fontSize: 15, color: cl.textPrimary),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            clearButtonMode: OverlayVisibilityMode.editing,
                            decoration: const BoxDecoration(color: Colors.transparent),
                            onChanged: (val) => setState(() => _hasInput = val.trim().isNotEmpty),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('You can always update this later in Settings.', style: GoogleFonts.poppins(fontSize: 12, color: cl.textSecondary)),
                        const SizedBox(height: 24),
                        AppButton(
                          txt: 'Continue',
                          color: _hasInput ? kPrimary : cl.textHint,
                          onTap: _hasInput ? () {
                            business.addBusinessData(BusinessModel(businessName: _nameCont.text.trim()));
                            business.getSaveBusinessModel();
                            Navigation.go(context, const InvoiceDummy());
                          } : null,
                        ),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
    );
  }
}
