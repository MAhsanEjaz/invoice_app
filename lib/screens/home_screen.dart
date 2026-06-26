import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/screens/dashboard_screen.dart';
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

  List<InvoiceModel> _filterForBusiness(
    List<InvoiceModel> all,
    BusinessModel? active,
    List<BusinessModel> allBusinesses,
  ) {
    if (active == null) return all;
    final knownIds = allBusinesses.map((b) => b.id).toSet();
    return all.where((inv) {
      if (inv.businessId == active.id) return true;
      if (inv.businessId == null && active.isDefault) return true;
      // Invoices whose business was deleted become orphans — show them under
      // the default business so they're never permanently hidden.
      if (active.isDefault && !knownIds.contains(inv.businessId)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return Consumer3<InvoiceProvider, CurrencyProvider, BusinessProvider>(
      builder: (context, invoice, currency, business, _) {
        final sym = currency.symbol;
        final active = business.activeBusiness;
        final filtered = _filterForBusiness(invoice.invoice, active, business.businesses);

        // Separate invoices from quotes/estimates
        final invoices = filtered
            .where((i) => (i.documentType ?? 'Invoice') == 'Invoice')
            .toList();
        final quotesEstimates = filtered
            .where((i) => (i.documentType ?? 'Invoice') != 'Invoice')
            .toList();
        final unpaid =
            invoices.where((i) => i.invoiceStatus != 'Paid').toList();
        final paid =
            invoices.where((i) => i.invoiceStatus == 'Paid').toList();
        final displayList = groupVal == 0
            ? unpaid
            : groupVal == 1
                ? paid
                : quotesEstimates;

        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, cl, business, filtered, sym),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: _buildSegmentControl(cl),
                ),
                Expanded(
                  child: displayList.isEmpty
                      ? _buildEmptyState(cl)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, k) => _buildInvoiceCard(
                            context,
                            cl,
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
                    txt: context.tr('create_invoice'),
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
    AppColors cl,
    BusinessProvider business,
    List<InvoiceModel> filtered,
    String sym,
  ) {
    final unpaidTotal = filtered
        .where((i) => (i.documentType ?? 'Invoice') == 'Invoice' && i.invoiceStatus != 'Paid')
        .fold<double>(0, (sum, inv) {
          final subtotal = inv.items?.fold<double>(0, (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1))) ?? 0;
          final discount = inv.discount ?? 0;
          final received = inv.receivedAmount ?? 0;
          return sum + (subtotal - discount - received).clamp(0.0, double.infinity);
        });

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('invoices'),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: cl.textPrimary,
                  ),
                ),
                Text(
                  '${filtered.length} ${context.tr('total')} · $sym${unpaidTotal.toStringAsFixed(2)} ${context.tr('outstanding')}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: cl.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showBusinessSwitcher(context, cl, business),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cl.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          business.activeBusiness?.businessName ??
                              context.tr('select_business'),
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
            onTap: () => Navigation.go(context, const DashboardScreen()),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cl.surface,
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
                CupertinoIcons.chart_bar_square,
                color: kPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigation.go(context, SettingPage()),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cl.surface,
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

  void _showBusinessSwitcher(
      BuildContext context, AppColors cl, BusinessProvider business) {
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

  Widget _buildSegmentControl(AppColors cl) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.border),
      ),
      child: Row(
        children: [
          _segmentTab(cl, context.tr('unpaid'), 0),
          const SizedBox(width: 4),
          _segmentTab(cl, context.tr('paid'), 1),
          const SizedBox(width: 4),
          _segmentTab(cl, context.tr('quotes_estimates'), 2),
        ],
      ),
    );
  }

  Widget _segmentTab(AppColors cl, String label, int index) {
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
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : cl.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors cl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cl.primaryLight,
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
            groupVal == 0
                ? context.tr('no_unpaid')
                : groupVal == 1
                    ? context.tr('no_paid')
                    : context.tr('no_quotes'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cl.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('tap_create'),
            style: GoogleFonts.poppins(
                fontSize: 13, color: cl.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    AppColors cl,
    InvoiceProvider invoice,
    InvoiceModel inv,
    String sym,
  ) {
    final clientName = (inv.clients?.isNotEmpty ?? false)
        ? (inv.clients!.first.name ?? 'Unknown Client')
        : 'Unknown Client';
    final subtotal = inv.items?.fold<double>(0, (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1))) ?? 0.0;
    final total = (subtotal - (inv.discount ?? 0) - (inv.receivedAmount ?? 0)).clamp(0.0, double.infinity);
    return GestureDetector(
      onTap: () {
        final latest = invoice.invoice.firstWhere(
          (e) => e.invoiceId == inv.invoiceId,
        );
        Navigation.go(
          context,
          VerificationInvoice(
            invoiceModel: latest,
            clientModel: (latest.clients?.isNotEmpty ?? false)
                ? latest.clients!.first
                : null,
            itemModel: (latest.items?.isNotEmpty ?? false)
                ? latest.items!.first
                : null,
          ),
        );
      },
      child: Container(
        decoration: context.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cl.primaryLight,
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
                      color: cl.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${inv.date ?? ''}  ·  #${inv.invoiceId}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: cl.textSecondary,
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
                    color: cl.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                documentBadge(context, inv),
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
    final cl = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: cl.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: cl.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                context.tr('switch_business'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cl.textPrimary,
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
                      color: isActive ? cl.primaryLight : cl.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? kPrimary : cl.border,
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
                            color: isActive ? kPrimary : cl.background,
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
                              color:
                                  isActive ? Colors.white : cl.textSecondary,
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
                              color: cl.textPrimary,
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
                              context.tr('default_label'),
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
                          Icon(
                            CupertinoIcons.circle,
                            color: cl.textHint,
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
