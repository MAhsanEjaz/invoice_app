import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/screens/setting_page.dart';
import 'package:invoicemaker/screens/verification_invoice.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';

import 'new_invoice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int groupVal = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoice, _) {
        final displayList =
            groupVal == 0 ? invoice.unPaidInvoice : invoice.paidInvoice;

        return CupertinoPageScaffold(
          backgroundColor: kBackground,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, invoice),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildSegmentControl(),
                ),
                Expanded(
                  child:
                      displayList.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                            itemCount: displayList.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder:
                                (context, k) => _buildInvoiceCard(
                                  context,
                                  invoice,
                                  displayList[k],
                                ),
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AppButton(
                    onTap: () => Navigation.go(context, NewInvoiceScreen()),
                    txt: 'Create Invoice',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, InvoiceProvider invoice) {
    final unpaidTotal = invoice.unPaidInvoice.fold<double>(
      0,
      (sum, inv) =>
          sum +
          (inv.items?.fold<double>(
                0,
                (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1)),
              ) ??
              0),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoices',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  '${invoice.invoice.length} total · \$${unpaidTotal.toStringAsFixed(2)} outstanding',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigation.go(context, SettingPage()),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.settings,
                color: kPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          _segmentTab('Unpaid', 0),
          const SizedBox(width: 4),
          _segmentTab('Paid', 1),
        ],
      ),
    );
  }

  Widget _segmentTab(String label, int index) {
    final isSelected = groupVal == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => groupVal = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : kTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.doc_text,
              size: 32,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            groupVal == 0 ? 'No unpaid invoices' : 'No paid invoices',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Create Invoice" to get started',
            style: GoogleFonts.poppins(fontSize: 13, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    InvoiceProvider invoice,
    InvoiceModel inv,
  ) {
    final clientName = inv.clients?.first.name ?? 'Unknown Client';
    final total =
        inv.items?.fold<double>(
          0,
          (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1)),
        ) ??
        0.0;
    final isPaid = inv.invoiceStatus == 'Paid';

    return GestureDetector(
      onTap: () {
        final latest = invoice.invoice.firstWhere(
          (e) => e.invoiceId == inv.invoiceId,
        );
        Navigation.go(
          context,
          VerificationInvoice(
            invoiceModel: latest,
            clientModel: latest.clients!.first,
            itemModel: latest.items!.first,
          ),
        );
      },
      child: Container(
        decoration: kCardDecoration,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                clientName.isNotEmpty
                    ? clientName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${inv.date ?? ''}  ·  #${inv.invoiceId}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                statusBadge(isPaid),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
