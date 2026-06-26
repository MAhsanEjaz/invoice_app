import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';

class InvoiceDummy extends StatelessWidget {
  const InvoiceDummy({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return Scaffold(
      backgroundColor: cl.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                context.tr('onboard_title'),
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: cl.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('onboard_subtitle'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: cl.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _FeatureItem(
                icon: CupertinoIcons.doc_richtext,
                title: context.tr('onboard_f1_title'),
                subtitle: context.tr('onboard_f1_sub'),
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.doc_on_doc_fill,
                title: context.tr('onboard_f2_title'),
                subtitle: context.tr('onboard_f2_sub'),
                iconColor: kQuoteColor,
                iconBg: cl.quoteBg,
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.chart_bar_alt_fill,
                title: context.tr('onboard_f3_title'),
                subtitle: context.tr('onboard_f3_sub'),
                iconColor: kEstimateColor,
                iconBg: cl.estimateBg,
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.checkmark_seal_fill,
                title: context.tr('onboard_f4_title'),
                subtitle: context.tr('onboard_f4_sub'),
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.person_2_fill,
                title: context.tr('onboard_f5_title'),
                subtitle: context.tr('onboard_f5_sub'),
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.share,
                title: context.tr('onboard_f6_title'),
                subtitle: context.tr('onboard_f6_sub'),
              ),
              const SizedBox(height: 12),
              _MockInvoiceCard(),
              const SizedBox(height: 16),

              AppButton(
                txt: context.tr('get_started'),
                onTap: () => Navigation.clearAll(context, const HomeScreen()),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final Color? iconBg;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg ?? cl.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? kPrimary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cl.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: cl.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MockInvoiceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  'My Business',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  'INVOICE',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _mockRow(cl, 'Client Name', '#001  ·  Jan 01, 2025'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Unpaid  ·  \$1,200.00',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockRow(AppColors cl, String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cl.textPrimary)),
        Text(right,
            style:
                GoogleFonts.poppins(fontSize: 12, color: cl.textSecondary)),
      ],
    );
  }
}
