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
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // ── Hero icon ─────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text_fill,
                  size: 38,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "You're all set!",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                'Create professional invoices in seconds\nand get paid faster.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: kTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // ── Feature list ──────────────────────────────────────────────
              _FeatureItem(
                icon: CupertinoIcons.doc_richtext,
                title: 'Beautiful PDF invoices',
                subtitle: 'Pick a color theme and share instantly',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: CupertinoIcons.checkmark_seal_fill,
                title: 'Track paid & unpaid',
                subtitle: 'Mark invoices as paid with one tap',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: CupertinoIcons.person_2_fill,
                title: 'Client management',
                subtitle: 'Import contacts or add clients manually',
              ),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: CupertinoIcons.share,
                title: 'Share anywhere',
                subtitle: 'Send via email, WhatsApp, or any app',
              ),

              const Spacer(),

              // ── Mock invoice preview ──────────────────────────────────────
              _MockInvoiceCard(),

              const Spacer(),

              AppButton(
                txt: 'Get Started',
                onTap: () => Navigation.clearAll(context, const HomeScreen()),
              ),

              const SizedBox(height: 24),
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

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimary, size: 20),
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
                  color: kTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: kTextSecondary,
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
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
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
          // Colored header strip
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
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _mockRow('Client Name', '#001  ·  Jan 01, 2025'),
                const SizedBox(height: 10),
                // Table header (colored)
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
                _mockItemRow('Design Services', '2', '\$400.00'),
                _mockItemRow('Development', '1', '\$250.00'),
                const Divider(height: 16, color: kBorder),
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      'TOTAL: ',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kTextSecondary,
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

  Widget _mockRow(String left, String right) {
    return Row(
      children: [
        Text(
          left,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        const Spacer(),
        Text(
          right,
          style: GoogleFonts.poppins(fontSize: 11, color: kTextSecondary),
        ),
      ],
    );
  }

  Widget _mockItemRow(String name, String qty, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: GoogleFonts.poppins(fontSize: 11, color: kTextPrimary),
            ),
          ),
          Text(
            qty,
            style: GoogleFonts.poppins(fontSize: 11, color: kTextSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
