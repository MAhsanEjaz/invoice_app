import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:invoicemaker/widgets/app_text_filed.dart';
import 'package:provider/provider.dart';

class BusinessUpatePage extends StatefulWidget {
  final BusinessModel? business;

  const BusinessUpatePage({super.key, this.business});

  @override
  State<BusinessUpatePage> createState() => _BusinessUpatePageState();
}

class _BusinessUpatePageState extends State<BusinessUpatePage> {
  final TextEditingController businessCont = TextEditingController();
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BusinessProvider>(context, listen: false);
      final target = widget.business ?? provider.activeBusiness;
      businessCont.text = target?.businessName ?? '';
      _logoPath = target?.businessLogo ?? '';
      provider.imagePath = _logoPath;
      setState(() {});
    });
  }

  @override
  void dispose() {
    businessCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: Column(
            children: [
              _buildNavBar(cl),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 8),
                    Center(child: _buildLogoPicker(cl, business)),
                    const SizedBox(height: 24),
                    sectionLabel(context, 'Business Name'),
                    Container(
                      decoration: context.cardDecoration,
                      child: AppTextFiled(controller: businessCont, placeholder: 'Business Name'),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cl.surface,
                  border: Border(top: BorderSide(color: cl.border)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: AppButton(
                  txt: 'Save Changes',
                  onTap: () async {
                    final name = businessCont.text.trim();
                    if (widget.business != null) {
                      await business.updateBusiness(widget.business!.id, name, business.imagePath);
                    } else {
                      await business.updateBusinessData(name);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavBar(AppColors cl) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          closeButton(context),
          const Spacer(),
          Text('Edit Business', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: cl.textPrimary)),
          const Spacer(),
          const SizedBox(width: 34),
        ]),
      ),
    );
  }

  Widget _buildLogoPicker(AppColors cl, BusinessProvider business) {
    final displayPath = business.imagePath;
    return GestureDetector(
      onTap: () async {
        final targetId = widget.business?.id ?? business.activeBusiness?.id;
        final newPath = await business.imagePickFunction(businessId: targetId);
        if (newPath != null) setState(() => _logoPath = newPath);
      },
      child: Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          color: cl.primaryLight,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cl.border, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: displayPath != null && displayPath.isNotEmpty
              ? Image.file(File(displayPath), fit: BoxFit.cover)
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(CupertinoIcons.camera_fill, color: kPrimary, size: 28),
                  const SizedBox(height: 6),
                  Text('Add Logo', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: kPrimary)),
                ]),
        ),
      ),
    );
  }
}
