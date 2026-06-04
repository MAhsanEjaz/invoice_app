import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
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

  // Returns invoices for the active business.
  // Legacy invoices without a businessId are shown under the default business.
  List<InvoiceModel> _filterForBusiness(
    List<InvoiceModel> all,
    BusinessModel? active,
  ) {
    if (active == null) return all;
    return all.where((inv) {
      if (inv.businessId == active.id) return true;
      // Legacy invoices (no businessId) belong to default business
      if (inv.businessId == null && active.isDefault) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<InvoiceProvider, CurrencyProvider, BusinessProvider>(
      builder: (context, invoice, currency, business, _) {
        final sym = currency.symbol;
        final active = business.activeBusiness;
        final filtered = _filterForBusiness(invoice.invoice, active);

        final unpaid =
            filtered.where((i) => i.invoiceStatus != 'Paid').toList();
        final paid =
            filtered.where((i) => i.invoiceStatus == 'Paid').toList();
        final displayList = groupVal == 0 ? unpaid : paid;

        return CupertinoPageScaffold(
          backgroundColor: kBackground,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, business, filtered, sym),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildSegmentControl(),
                ),
                Expanded(
                  child: displayList.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, k) => _buildInvoiceCard(
                            context,
                            invoice,
                            displayList[k],
                            sym,
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

  Widget _buildHeader(
    BuildContext context,
    BusinessProvider business,
    List<InvoiceModel> filtered,
    String sym,
  ) {
    final unpaidTotal = filtered
        .where((i) => i.invoiceStatus != 'Paid')
        .fold<double>(
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
                  '${filtered.length} total · $sym${unpaidTotal.toStringAsFixed(2)} outstanding',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                // Business switcher chip
                GestureDetector(
                  onTap: () =>
                      _showBusinessSwitcher(context, business),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          business.activeBusiness?.businessName ??
                              'Select Business',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: 11,
                          color: kPrimary,
                        ),
                      ],
                    ),
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

  void _showBusinessSwitcher(BuildContext context, BusinessProvider business) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusinessSwitcherSheet(
        businesses: business.businesses,
        activeId: business.activeBusiness?.id,
        onSelect: (b) {
          business.setActiveBusiness(b);
          Navigator.pop(context);
        },
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
            style: GoogleFonts.poppins(
                fontSize: 13, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    InvoiceProvider invoice,
    InvoiceModel inv,
    String sym,
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
                clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
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
                  '$sym${total.toStringAsFixed(2)}',
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

class _BusinessSwitcherSheet extends StatelessWidget {
  final List<BusinessModel> businesses;
  final String? activeId;
  final void Function(BusinessModel) onSelect;

  const _BusinessSwitcherSheet({
    required this.businesses,
    required this.activeId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Switch Business',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: businesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final b = businesses[i];
                final isActive = b.id == activeId;
                return GestureDetector(
                  onTap: () => onSelect(b),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? kPrimaryLight : kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? kPrimary : kBorder,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isActive ? kPrimary : kBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (b.businessName?.isNotEmpty ?? false)
                                ? b.businessName![0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : kTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            b.businessName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                        ),
                        if (b.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Default',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (isActive)
                          const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: kPrimary,
                            size: 20,
                          )
                        else
                          const Icon(
                            CupertinoIcons.circle,
                            color: kTextHint,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
