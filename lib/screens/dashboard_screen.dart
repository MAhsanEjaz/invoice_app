import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/screens/verification_invoice.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  double _invoiceTotal(InvoiceModel inv) {
    final subtotal = inv.items?.fold<double>(0, (s, i) => s + i.lineTotal) ?? 0;
    final afterDiscount =
        (subtotal - (inv.discount ?? 0)).clamp(0.0, double.infinity);
    final taxAmount = afterDiscount * (inv.taxRate ?? 0) / 100;
    return afterDiscount + taxAmount;
  }

  double _balanceDue(InvoiceModel inv) {
    final total = _invoiceTotal(inv);
    return (total - (inv.receivedAmount ?? 0)).clamp(0.0, double.infinity);
  }

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
      if (active.isDefault && !knownIds.contains(inv.businessId)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;

    return Consumer3<InvoiceProvider, CurrencyProvider, BusinessProvider>(
      builder: (context, invoiceProvider, currency, business, _) {
        final sym = currency.symbol;
        final active = business.activeBusiness;
        final all = _filterForBusiness(
            invoiceProvider.invoice, active, business.businesses);

        final invoices =
            all.where((i) => (i.documentType ?? 'Invoice') == 'Invoice').toList();
        final paid = invoices.where((i) => i.invoiceStatus == 'Paid').toList();
        final unpaid =
            invoices.where((i) => i.invoiceStatus != 'Paid').toList();

        final now = DateTime.now();
        final thisMonthInvoices = invoices.where((inv) {
          if (inv.date == null) return false;
          try {
            final parsed = DateFormat('MMM dd, yyyy').parse(inv.date!);
            return parsed.year == now.year && parsed.month == now.month;
          } catch (_) {
            try {
              final parsed = DateTime.parse(inv.date!);
              return parsed.year == now.year && parsed.month == now.month;
            } catch (_) {
              return false;
            }
          }
        }).toList();

        final totalEarned =
            paid.fold<double>(0, (s, inv) => s + _invoiceTotal(inv));
        final totalOutstanding =
            unpaid.fold<double>(0, (s, inv) => s + _balanceDue(inv));
        final thisMonthRevenue =
            thisMonthInvoices.fold<double>(0, (s, inv) => s + _invoiceTotal(inv));

        final recent = [...all]
          ..sort((a, b) => (b.invoiceId ?? 0).compareTo(a.invoiceId ?? 0));
        final recentSlice = recent.take(8).toList();

        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: SafeArea(
            child: Column(
              children: [
                _buildNavBar(context, cl),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _statsGrid(context, cl, sym, totalEarned,
                          totalOutstanding, thisMonthRevenue,
                          paid.length, unpaid.length),
                      const SizedBox(height: 28),
                      _sectionLabel(context, cl, context.tr('recent_invoices')),
                      const SizedBox(height: 12),
                      if (recentSlice.isEmpty)
                        _emptyState(context, cl)
                      else
                        ...recentSlice.map(
                          (inv) => _invoiceTile(context, cl, sym, inv),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBar(BuildContext context, AppColors cl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(CupertinoIcons.back, color: kPrimary, size: 26),
          ),
          const SizedBox(width: 12),
          Text(
            context.tr('dashboard'),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cl.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(
    BuildContext context,
    AppColors cl,
    String sym,
    double earned,
    double outstanding,
    double thisMonth,
    int paidCount,
    int unpaidCount,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                context, cl,
                label: context.tr('total_earned'),
                value: '$sym${earned.toStringAsFixed(2)}',
                icon: CupertinoIcons.checkmark_seal_fill,
                iconColor: kPaidColor,
                sub: '${context.tr('paid_count')}: $paidCount',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                context, cl,
                label: context.tr('outstanding'),
                value: '$sym${outstanding.toStringAsFixed(2)}',
                icon: CupertinoIcons.clock_fill,
                iconColor: kUnpaidColor,
                sub: '${context.tr('invoices_count')}: $unpaidCount',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _statCard(
          context, cl,
          label: context.tr('this_month'),
          value: '$sym${thisMonth.toStringAsFixed(2)}',
          icon: CupertinoIcons.calendar,
          iconColor: kPrimary,
          sub: '',
          wide: true,
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    AppColors cl, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String sub,
    bool wide = false,
  }) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: wide
          ? Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: cl.textSecondary)),
                    Text(value,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: cl.textPrimary)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(height: 10),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: cl.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cl.textPrimary)),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sub,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: cl.textSecondary)),
                ],
              ],
            ),
    );
  }

  Widget _sectionLabel(BuildContext context, AppColors cl, String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: cl.textPrimary,
      ),
    );
  }

  Widget _invoiceTile(
    BuildContext context,
    AppColors cl,
    String sym,
    InvoiceModel inv,
  ) {
    final docType = inv.documentType ?? 'Invoice';
    final isInvoice = docType == 'Invoice';
    final isPaid = inv.invoiceStatus == 'Paid';
    final total = _invoiceTotal(inv);
    final balanceDue = _balanceDue(inv);

    final statusColor = !isInvoice
        ? kQuoteColor
        : isPaid
            ? kPaidColor
            : kUnpaidColor;

    final docLabel = isInvoice
        ? (isPaid ? context.tr('paid') : context.tr('unpaid'))
        : docType;

    final displayNumber = inv.invoiceNumber ??
        '#${inv.invoiceId ?? ''}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => VerificationInvoice(invoiceModel: inv),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isInvoice
                    ? CupertinoIcons.doc_text_fill
                    : CupertinoIcons.doc_plaintext,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (inv.clients?.isNotEmpty ?? false)
                        ? (inv.clients!.first.name ?? displayNumber)
                        : displayNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cl.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    displayNumber,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: cl.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sym${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cl.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isInvoice && !isPaid
                        ? '$sym${balanceDue.toStringAsFixed(2)} ${context.tr('pdf_due')}'
                        : docLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, AppColors cl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.doc_text,
                size: 48, color: cl.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              context.tr('no_activity'),
              style: GoogleFonts.poppins(
                  fontSize: 14, color: cl.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
