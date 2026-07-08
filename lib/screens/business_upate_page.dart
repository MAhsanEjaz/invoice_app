import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:invoicemaker/widgets/app_tap.dart';
import 'package:invoicemaker/widgets/app_text_filed.dart';
import 'package:invoicemaker/widgets/responsive.dart';
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
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: ResponsiveCenter(
            maxWidth: 640,
            child: Column(
              children: [
                _buildNavBar(cl),
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
                        Center(child: _buildLogoPicker(cl, business)),
                        const SizedBox(height: 24),
                        sectionLabel(
                          context,
                          context.tr('business_name_label'),
                        ),
                        Container(
                          decoration: context.cardDecoration,
                          child: AppTextFiled(
                            controller: businessCont,
                            placeholder: context.tr('business_name_label'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cl.surface,
                    border: Border(top: BorderSide(color: cl.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: AppButton(
                    txt: context.tr('save_changes'),
                    onTap: () async {
                      final name = businessCont.text.trim();
                      if (widget.business != null) {
                        await business.updateBusiness(
                          widget.business!.id,
                          name,
                          business.imagePath,
                        );
                      } else {
                        await business.updateBusinessData(name);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
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
        child: Row(
          children: [
            closeButton(context),
            const Spacer(),
            Text(
              context.tr('edit_business'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cl.textPrimary,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPicker(AppColors cl, BusinessProvider business) {
    final displayPath = business.imagePath;
    final hasLogo = displayPath != null && displayPath.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppTap(
          onTap: () async {
            final targetId = widget.business?.id ?? business.activeBusiness?.id;
            final newPath = await business.imagePickFunction(
              businessId: targetId,
            );
            if (newPath != null) setState(() => _logoPath = newPath);
          },
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: cl.primaryLight,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cl.border, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child:
                  hasLogo
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
                            context.tr('add_logo'),
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
        ),
        if (hasLogo)
          Positioned(
            top: -6,
            right: -6,
            child: AppTap(
              onTap: () {
                business.imagePath = null;
                setState(() => _logoPath = null);
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: cl.surface, width: 2),
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
