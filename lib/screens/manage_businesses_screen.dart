import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';

import 'business_upate_page.dart';

class ManageBusinessesScreen extends StatelessWidget {
  const ManageBusinessesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: Column(
            children: [
              _buildNavBar(context, cl),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      sectionLabel(context, context.tr('your_businesses')),
                      const SizedBox(height: 8),
                      if (business.businesses.isEmpty)
                        _buildEmpty(context, cl)
                      else
                        _buildBusinessList(context, cl, business),
                      const SizedBox(height: 24),
                      AppButton(
                        txt: context.tr('add_new_business'),
                        onTap: () => _showAddDialog(context, business),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavBar(BuildContext context, AppColors cl) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          closeButton(context),
          const Spacer(),
          Text(context.tr('manage_businesses'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: cl.textPrimary)),
          const Spacer(),
          const SizedBox(width: 34),
        ]),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppColors cl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(context.tr('no_businesses_yet'), style: GoogleFonts.poppins(fontSize: 14, color: cl.textSecondary)),
      ),
    );
  }

  Widget _buildBusinessList(BuildContext context, AppColors cl, BusinessProvider business) {
    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: business.businesses.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: cl.border),
          itemBuilder: (context, index) {
            final b = business.businesses[index];
            final isActive = business.activeBusiness?.id == b.id;
            return _BusinessTile(
              business: b,
              isActive: isActive,
              canDelete: business.businesses.length > 1,
              onSetActive: () => business.setActiveBusiness(b),
              onSetDefault: () => business.setDefaultBusiness(b.id),
              onEdit: () => Navigation.go(context, BusinessUpatePage(business: b)),
              onDelete: () => _confirmDelete(context, business, b),
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, BusinessProvider business) {
    final ctrl = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(context.tr('new_business'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: ctrl, autofocus: true, placeholder: context.tr('business_name_placeholder'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          CupertinoDialogAction(isDestructiveAction: true, child: Text(context.tr('cancel')), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true, child: Text(context.tr('add')),
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) business.addBusiness(name);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BusinessProvider business, BusinessModel b) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(context.tr('delete_business'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('"${b.businessName}" — ${context.tr('confirm_delete_business')}', style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          CupertinoDialogAction(child: Text(context.tr('cancel')), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(isDestructiveAction: true, child: Text(context.tr('delete')), onPressed: () { business.deleteBusiness(b.id); Navigator.pop(context); }),
        ],
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  final BusinessModel business;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onSetActive;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BusinessTile({
    required this.business,
    required this.isActive,
    required this.canDelete,
    required this.onSetActive,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    final name = business.businessName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final logoPath = business.businessLogo;
    final hasLogo = logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync();

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onSetActive,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: cl.primaryLight, borderRadius: BorderRadius.circular(13)),
              clipBehavior: Clip.hardEdge,
              child: hasLogo
                  ? Image.file(File(logoPath), fit: BoxFit.cover)
                  : Center(child: Text(initial, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimary))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: cl.textPrimary)),
              const SizedBox(height: 2),
              Row(children: [
                if (isActive) _badge(kPrimary, context.tr('active')),
                if (isActive && business.isDefault) const SizedBox(width: 6),
                if (business.isDefault) _badge(Colors.orange, context.tr('default_label')),
              ]),
            ])),
            PopupMenuButton<String>(
              icon: Icon(CupertinoIcons.ellipsis_vertical, size: 18, color: cl.textSecondary),
              color: cl.surface,
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'default') onSetDefault();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(context.tr('edit'), style: GoogleFonts.poppins(fontSize: 14, color: cl.textPrimary))),
                if (!business.isDefault)
                  PopupMenuItem(value: 'default', child: Text(context.tr('set_as_default'), style: GoogleFonts.poppins(fontSize: 14, color: cl.textPrimary))),
                if (canDelete)
                  PopupMenuItem(value: 'delete', child: Text(context.tr('delete'), style: GoogleFonts.poppins(fontSize: 14, color: Colors.red))),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _badge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
