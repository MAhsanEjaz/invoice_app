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
  // If null, edits the currently active business.
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
      // Sync provider imagePath so the logo picker widget stays consistent
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
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return CupertinoPageScaffold(
          backgroundColor: kBackground,
          child: Column(
            children: [
              _buildNavBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Center(child: _buildLogoPicker(business)),
                      const SizedBox(height: 24),
                      sectionLabel('Business Name'),
                      Container(
                        decoration: kCardDecoration,
                        child: AppTextFiled(
                          controller: businessCont,
                          placeholder: 'Business Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: kSurface,
                  border: Border(top: BorderSide(color: kBorder)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: AppButton(
                  txt: 'Save Changes',
                  onTap: () async {
                    final name = businessCont.text.trim();
                    if (widget.business != null) {
                      // Editing a specific business (from ManageBusinessesScreen)
                      await business.updateBusiness(
                        widget.business!.id,
                        name,
                        business.imagePath,
                      );
                    } else {
                      // Editing the active business (from SettingPage)
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

  Widget _buildNavBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            closeButton(context),
            const Spacer(),
            Text(
              'Edit Business',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPicker(BusinessProvider business) {
    final displayPath = business.imagePath;
    return GestureDetector(
      onTap: () async {
        final targetId = widget.business?.id ?? business.activeBusiness?.id;
        final newPath = await business.imagePickFunction(businessId: targetId);
        if (newPath != null) {
          setState(() => _logoPath = newPath);
        }
      },
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: kPrimaryLight,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kBorder, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: displayPath != null && displayPath.isNotEmpty
              ? Image.file(File(displayPath), fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.camera_fill,
                      color: kPrimary,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add Logo',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
