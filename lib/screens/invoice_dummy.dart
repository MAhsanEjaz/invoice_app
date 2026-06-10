import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';

import 'home_screen.dart';

class InvoiceDummy extends StatelessWidget {
  const InvoiceDummy({super.key});

  @override
  Widget build(BuildContext context) {
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
                "You're all set!",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: cl.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Create professional invoices in seconds\nand get paid faster.',
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
                title: 'Beautiful PDF invoices',
                subtitle: 'Pick a color theme and share instantly',
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.doc_on_doc_fill,
                title: 'Quotes & proposals',
                subtitle: 'Send polished quotes to win new clients',
                iconColor: kQuoteColor,
                iconBg: cl.quoteBg,
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.chart_bar_alt_fill,
                title: 'Estimates & budgets',
                subtitle: 'Set cost expectations before work begins',
                iconColor: kEstimateColor,
                iconBg: cl.estimateBg,
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.checkmark_seal_fill,
                title: 'Track paid & unpaid',
                subtitle: 'Mark invoices as paid with one tap',
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.person_2_fill,
                title: 'Client management',
                subtitle: 'Import contacts or add clients manually',
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: CupertinoIcons.share,
                title: 'Share anywhere',
                subtitle: 'Send via email, WhatsApp, or any app',
              ),
              const SizedBox(height: 12),
              _MockInvoiceCard(),
              const SizedBox(height: 16),

              AppButton(
                txt: 'Get Started',
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
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'DESCRIPTION',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'QTY',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'AMOUNT',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _mockItemRow(cl, 'Design Services', '2', '\$400.00'),
                _mockItemRow(cl, 'Development', '1', '\$250.00'),
                Divider(height: 16, color: cl.border),
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      'TOTAL: ',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cl.textSecondary,
                      ),
                    ),
                    Text(
                      '\$650.00',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ],
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
      children: [
        Text(
          left,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cl.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          right,
          style: GoogleFonts.poppins(fontSize: 11, color: cl.textSecondary),
        ),
      ],
    );
  }

  Widget _mockItemRow(AppColors cl, String name, String qty, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: GoogleFonts.poppins(fontSize: 11, color: cl.textPrimary),
            ),
          ),
          Text(
            qty,
            style: GoogleFonts.poppins(fontSize: 11, color: cl.textSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cl.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
