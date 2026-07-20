import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/pdf/pdf_service.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/screens/home_screen.dart';
import 'package:invoicemaker/screens/invoice_preview_screen.dart';
import 'package:invoicemaker/screens/new_invoice_screen.dart';
import 'package:invoicemaker/services/export_helper.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_tap.dart';
import 'package:invoicemaker/widgets/responsive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bank_model.dart';
import '../providers/bank_provider.dart';
import '../providers/business_provider.dart';
import '../providers/invoice_number_provider.dart';
import '../providers/pdf_templates_colors_provider.dart';

class VerificationInvoice extends StatefulWidget {
  final ClientModel? clientModel;
  final ItemModel? itemModel;
  final InvoiceModel? invoiceModel;
  final bool cameFromCreation;

  const VerificationInvoice({
    super.key,
    this.itemModel,
    this.clientModel,
    this.invoiceModel,
    this.cameFromCreation = false,
  });

  @override
  State<VerificationInvoice> createState() => _VerificationInvoiceState();
}

class _VerificationInvoiceState extends State<VerificationInvoice> {
  bool _isExporting = false;

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // System/hardware back should return to whichever screen pushed this
  // invoice (Dashboard, Home list, etc.) instead of always resetting to
  // Home — except right after creating a new invoice, where the previous
  // screen is a cleared-out creation form we don't want to land back on.
  void _goBack() {
    if (!widget.cameFromCreation && Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _goHome();
    }
  }

  // ── Currency formatter ─────────────────────────────────────────────────────
  String _fmt(String sym, double amount) =>
      '$sym${NumberFormat('#,##0.00', 'en_US').format(amount)}';

  // ── Shared amount input dialog (cross-platform) ────────────────────────────
  void _showAmountDialog({
    required String title,
    required String confirmLabel,
    required double current,
    required void Function(double) onConfirm,
  }) {
    final ctrl = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(2) : '',
    );

    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: context.colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.poppins(color: context.colors.textHint),
                filled: true,
                fillColor: context.colors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimary, width: 1.5),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  context.tr('cancel'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(ctrl.text.trim()) ?? 0;
                  onConfirm(amount);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Received-amount dialog ─────────────────────────────────────────────────
  void _showReceivedDialog(InvoiceProvider invoice, double current) {
    _showAmountDialog(
      title: context.tr('received_amount'),
      confirmLabel: context.tr('save'),
      current: current,
      onConfirm:
          (amount) => invoice.updateReceivedAmount(
            widget.invoiceModel!.invoiceId!,
            amount,
          ),
    );
  }

  // ── Discount dialog ────────────────────────────────────────────────────────
  void _showDiscountDialog(InvoiceProvider invoice, double current) {
    _showAmountDialog(
      title: context.tr('discount_amount'),
      confirmLabel: context.tr('apply'),
      current: current,
      onConfirm:
          (amount) =>
              invoice.updateDiscount(widget.invoiceModel!.invoiceId!, amount),
    );
  }

  // ── Bank picker sheet ──────────────────────────────────────────────────────
  void _showBankPicker(
    InvoiceProvider invoiceProvider,
    InvoiceModel liveInvoice,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Consumer<BankProvider>(
            builder: (_, bankProvider, __) {
              final banks = bankProvider.banks;
              return Container(
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
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
                          color: context.colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.tr('select_bank_account'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (banks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.creditcard,
                                size: 40,
                                color: context.colors.textHint,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('no_bank_accounts'),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('go_settings_bank'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: context.colors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: banks.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final b = banks[index];
                              final isSelected = b.id == liveInvoice.bank?.id;
                              return AppTap(
                                onTap: () {
                                  Navigator.pop(context);
                                  invoiceProvider.updateInvoiceBank(
                                    liveInvoice.invoiceId!,
                                    b,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? context.colors.primaryLight
                                            : context.colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? kPrimary
                                              : context.colors.border,
                                      width: isSelected ? 1.5 : 1,
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
                                          color:
                                              isSelected
                                                  ? kPrimary
                                                  : context.colors.background,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.creditcard,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : context
                                                      .colors
                                                      .textSecondary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              b.title ?? '',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    context.colors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '${b.bankName}  •  ${b.accountNumber}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color:
                                                    context
                                                        .colors
                                                        .textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? CupertinoIcons
                                                .checkmark_circle_fill
                                            : CupertinoIcons.circle,
                                        color:
                                            isSelected
                                                ? kPrimary
                                                : context.colors.textHint,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (liveInvoice.bank != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AppTap(
                            onTap: () {
                              Navigator.pop(context);
                              invoiceProvider.updateInvoiceBank(
                                liveInvoice.invoiceId!,
                                null,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: context.colors.dangerBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kDangerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  context.tr('remove_bank'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kDangerColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────────
  void _confirmDelete(InvoiceProvider invoice) {
    showCupertinoDialog<void>(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text(
              context.tr('delete_invoice'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(() {
                final docType = widget.invoiceModel!.documentType ?? 'Invoice';
                final prefix =
                    docType == 'Quote'
                        ? context.tr('quote_no')
                        : docType == 'Estimate'
                        ? context.tr('estimate_no')
                        : context.tr('pdf_invoice_no');
                return '$prefix${widget.invoiceModel!.invoiceId} ${context.tr('invoice_delete_suffix')}';
              }(), style: GoogleFonts.poppins(fontSize: 13)),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr('cancel'),
                  style: GoogleFonts.poppins(color: CupertinoColors.systemBlue),
                ),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  invoice.deleteWholeInvoice(widget.invoiceModel!.invoiceId!);
                  _goHome();
                },
                child: Text(
                  context.tr('delete'),
                  style: GoogleFonts.poppins(color: CupertinoColors.systemRed),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmConvert(
    InvoiceModel source,
    InvoiceProvider invoice,
    InvoiceNumberProvider numProvider,
  ) {
    showCupertinoDialog<void>(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text(
              context.tr('convert_to_invoice'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                context.tr('convert_confirm'),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr('cancel'),
                  style: GoogleFonts.poppins(color: CupertinoColors.systemBlue),
                ),
              ),
              CupertinoDialogAction(
                onPressed: () async {
                  Navigator.pop(context);
                  final newInvoice = await invoice.convertToInvoice(
                    source,
                    numberFormatter:
                        numProvider.isCustom ? numProvider.format : null,
                  );
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder:
                          (_) => VerificationInvoice(invoiceModel: newInvoice),
                    ),
                  );
                },
                child: Text(
                  context.tr('convert'),
                  style: GoogleFonts.poppins(color: CupertinoColors.systemBlue),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer<InvoiceProvider>(
      builder: (context, invoice, _) {
        // ── Always read the live invoice so edits are reflected immediately ──
        final liveInvoice = invoice.invoice.firstWhere(
          (e) => e.invoiceId == widget.invoiceModel!.invoiceId,
          orElse: () => widget.invoiceModel!,
        );

        final docType = liveInvoice.documentType ?? 'Invoice';
        final isInvoice = docType == 'Invoice';
        final isPaid = liveInvoice.invoiceStatus == 'Paid';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goBack();
          },
          child: CupertinoPageScaffold(
            backgroundColor: context.colors.background,
            child: ResponsiveCenter(
              maxWidth: 900,
              child: Column(
                children: [
                  _buildNavBar(liveInvoice, invoice, docType),
                  Expanded(
                    child: _buildBody(liveInvoice, isPaid, isInvoice, invoice),
                  ),
                  Consumer<TemplatesColorsProvider>(
                    builder:
                        (ctx, data, _) =>
                            _buildBottomBar(data, invoice, liveInvoice),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Nav bar ────────────────────────────────────────────────────────────────
  Widget _buildNavBar(
    InvoiceModel liveInvoice,
    InvoiceProvider invoice,
    String docType,
  ) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Back to home
            AppTap(
              onTap: _goHome,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: kPrimary,
                  size: 15,
                ),
              ),
            ),

            const Spacer(),
            Text(
              () {
                final id = liveInvoice.invoiceId;
                if (docType == 'Quote') return '${context.tr('quote_no')}$id';
                if (docType == 'Estimate') {
                  return '${context.tr('estimate_no')}$id';
                }
                return '${context.tr('pdf_invoice_no')}$id';
              }(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const Spacer(),

            // Edit
            AppTap(
              onTap:
                  () => Navigation.go(
                    context,
                    NewInvoiceScreen(
                      invoiceId: liveInvoice.invoiceId,
                      invoice: liveInvoice,
                    ),
                  ),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.pencil,
                  color: kPrimary,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(
    InvoiceModel liveInvoice,
    bool isPaid,
    bool isInvoice,
    InvoiceProvider invoice,
  ) {
    final sym = Provider.of<CurrencyProvider>(context).symbol;
    // All values derived from the live provider object
    final items = liveInvoice.items ?? [];
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final discount = liveInvoice.discount ?? 0;
    final afterDiscount = (subtotal - discount).clamp(0.0, double.infinity);
    final taxRate = liveInvoice.taxRate ?? 0;
    final taxAmount = afterDiscount * taxRate / 100;
    final total = afterDiscount + taxAmount;
    final received = liveInvoice.receivedAmount ?? 0;
    final balanceDue = (total - received).clamp(0.0, double.infinity);

    final client =
        (liveInvoice.clients?.isNotEmpty ?? false)
            ? liveInvoice.clients!.first
            : widget.clientModel;
    final clientName = client?.name ?? '';
    final clientEmail = client?.email ?? '';
    final clientPhone = client?.phone ?? '';
    final clientAddress = client?.address ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero amount card ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: context.cardDecoration,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(width: 4, color: kPrimary),
                  // Card content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              documentBadge(context, liveInvoice),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (liveInvoice.date?.isNotEmpty ?? false)
                                    Text(
                                      liveInvoice.date!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                  if (liveInvoice.dueDate?.isNotEmpty ?? false)
                                    Text(
                                      '${context.tr('due_label')} ${liveInvoice.dueDate}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: kUnpaidColor,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _fmt(sym, balanceDue),
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                              letterSpacing: -1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clientName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Client ────────────────────────────────────────────────────────
          const SizedBox(height: 20),
          sectionLabel(context, context.tr('client')),
          Container(
            decoration: context.cardDecoration,
            child: Column(
              children: [
                _infoRow(CupertinoIcons.person, context.tr('name'), clientName),
                if (clientEmail.isNotEmpty) ...[
                  Divider(height: 1, color: context.colors.border),
                  _infoRow(
                    CupertinoIcons.mail,
                    context.tr('email'),
                    clientEmail,
                  ),
                ],
                if (clientPhone.isNotEmpty) ...[
                  Divider(height: 1, color: context.colors.border),
                  _infoRow(
                    CupertinoIcons.phone,
                    context.tr('phone'),
                    clientPhone,
                  ),
                ],
                if (clientAddress.isNotEmpty) ...[
                  Divider(height: 1, color: context.colors.border),
                  _infoRow(
                    CupertinoIcons.location,
                    context.tr('address'),
                    clientAddress,
                  ),
                ],
              ],
            ),
          ),

          // ── Items ─────────────────────────────────────────────────────────
          const SizedBox(height: 20),
          sectionLabel(context, context.tr('items')),
          Container(
            decoration: context.cardDecoration,
            child: Column(
              children: [
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder:
                      (_, __) =>
                          Divider(height: 1, color: context.colors.border),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final hasDiscount = (item.discount ?? 0) > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.qty ?? 1} × ${_fmt(sym, item.price?.toDouble() ?? 0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: context.colors.textSecondary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.discountType == 'percent'
                                        ? '-${item.discount!.toStringAsFixed(1)}%'
                                        : '-${_fmt(sym, item.discount!)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: kDangerColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _fmt(sym, item.lineTotal),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Subtotal row
                Divider(height: 1, color: context.colors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        context.tr('pdf_subtotal'),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _fmt(sym, subtotal),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                // Discount row — always visible and tappable
                Divider(height: 1, color: context.colors.border),
                AppTap(
                  onTap: () => _showDiscountDialog(invoice, discount),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.tag,
                          size: 15,
                          color:
                              discount > 0
                                  ? kDangerColor
                                  : context.colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('pdf_discount'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color:
                                discount > 0
                                    ? kDangerColor
                                    : context.colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          discount > 0
                              ? '-${_fmt(sym, discount)}'
                              : _fmt(sym, 0),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                discount > 0
                                    ? kDangerColor
                                    : context.colors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          CupertinoIcons.pencil,
                          size: 13,
                          color: context.colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tax row — shown only when tax is applied
                if (taxRate > 0) ...[
                  Divider(height: 1, color: context.colors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.percent, size: 15, color: kPrimary),
                        const SizedBox(width: 8),
                        Text(
                          '${liveInvoice.taxLabel ?? context.tr('tax')} (${taxRate.toStringAsFixed(taxRate == taxRate.roundToDouble() ? 0 : 1)}%)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${_fmt(sym, taxAmount)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Total row — shown when discount or tax is applied
                if (discount > 0 || taxRate > 0) ...[
                  Divider(height: 1, color: context.colors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          context.tr('total'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmt(sym, total),
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Notes (shown only if present) ──────────────────────────────────
          if (liveInvoice.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            sectionLabel(context, context.tr('pdf_notes')),
            Container(
              width: double.infinity,
              decoration: context.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Text(
                liveInvoice.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: context.colors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── Terms & Conditions (shown only if included) ────────────────────
          if (liveInvoice.termsConditions?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            sectionLabel(context, context.tr('terms_conditions')),
            Container(
              width: double.infinity,
              decoration: context.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Text(
                liveInvoice.termsConditions!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── Bank / Payment Details ────────────────────────────────────────
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  context.tr('pdf_payment_details').toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (liveInvoice.bank != null)
                  AppTap(
                    onTap: () async {
                      final bank = liveInvoice.bank!;
                      final parts = <String>[];
                      if ((bank.bankName ?? '').isNotEmpty) {
                        parts.add(bank.bankName!);
                      }
                      if ((bank.title ?? '').isNotEmpty) parts.add(bank.title!);
                      if ((bank.accountNumber ?? '').isNotEmpty) {
                        parts.add(bank.accountNumber!);
                      }
                      await Clipboard.setData(
                        ClipboardData(text: parts.join('\n')),
                      );
                      if (mounted) _showToast(context.tr('copied'));
                    },
                    child: Icon(
                      CupertinoIcons.doc_on_clipboard,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: context.cardDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    if (liveInvoice.bank != null) ...[
                      _bankCard(liveInvoice.bank!),
                      Divider(height: 1, color: context.colors.border),
                    ],
                    InkWell(
                      borderRadius:
                          liveInvoice.bank == null
                              ? BorderRadius.circular(16)
                              : const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                      onTap: () => _showBankPicker(invoice, liveInvoice),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color:
                                    liveInvoice.bank == null
                                        ? context.colors.primaryLight
                                        : context.colors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                CupertinoIcons.creditcard,
                                color:
                                    liveInvoice.bank == null
                                        ? kPrimary
                                        : context.colors.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              liveInvoice.bank == null
                                  ? context.tr('add_bank_account')
                                  : context.tr('select_bank_account'),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color:
                                    liveInvoice.bank == null
                                        ? kPrimary
                                        : context.colors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: context.colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Payment (invoices only — not shown for quotes/estimates) ─────────
          if (isInvoice) ...[
            const SizedBox(height: 20),
            sectionLabel(context, context.tr('payment')),
            Container(
              decoration: context.cardDecoration,
              child: Column(
                children: [
                  // Mark as Paid toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          context.tr('mark_as_paid'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 0.85,
                          child: CupertinoSwitch(
                            value: isPaid,
                            activeTrackColor: kPrimary,
                            onChanged: (val) {
                              invoice.updateInvoiceStatus(
                                val ? 'Paid' : 'UnPaid',
                                liveInvoice.invoiceId!,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: context.colors.border),

                  // Received — tappable to enter amount
                  AppTap(
                    onTap: () => _showReceivedDialog(invoice, received),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.money_dollar_circle,
                            size: 16,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('pdf_received'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _fmt(sym, received),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  received > 0
                                      ? kPaidColor
                                      : context.colors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            CupertinoIcons.pencil,
                            size: 14,
                            color: context.colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Balance Due (only shown when not fully paid)
                  if (balanceDue > 0) ...[
                    Divider(height: 1, color: context.colors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.exclamationmark_circle,
                            size: 16,
                            color: kUnpaidColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('pdf_balance_due'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kUnpaidColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _fmt(sym, balanceDue),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kUnpaidColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Recurring (invoices only) ──────────────────────────────────────
          if (isInvoice) ...[
            const SizedBox(height: 20),
            sectionLabel(context, context.tr('repeat_invoice')),
            _buildRecurringSection(liveInvoice, invoice),
          ],

          // ── Convert to Invoice (Quotes & Estimates only) ───────────────────
          if (!isInvoice) ...[
            const SizedBox(height: 16),
            Consumer<InvoiceNumberProvider>(
              builder:
                  (ctx, numProvider, _) => AppTap(
                    onTap:
                        () =>
                            _confirmConvert(liveInvoice, invoice, numProvider),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.arrow_right_arrow_left,
                            color: kPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('convert_to_invoice'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],

          // ── Delete invoice ─────────────────────────────────────────────────
          const SizedBox(height: 24),
          AppTap(
            onTap: () => _confirmDelete(invoice),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kDangerColor.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.delete,
                    color: kDangerColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isInvoice
                        ? context.tr('delete_invoice')
                        : context.tr('delete_document'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kDangerColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Recurring section ─────────────────────────────────────────────────────
  Widget _buildRecurringSection(
    InvoiceModel liveInvoice,
    InvoiceProvider invoice,
  ) {
    final cl = context.colors;
    final isOn = liveInvoice.isRecurring == true;
    final interval = liveInvoice.recurringInterval ?? 'monthly';
    final nextDate = liveInvoice.nextRecurringDate;

    String intervalLabel() {
      switch (interval) {
        case 'weekly':
          return context.tr('interval_weekly');
        case 'custom':
          final days = liveInvoice.recurringCustomDays;
          return days != null
              ? '$days ${context.tr('custom_days_unit')}'
              : context.tr('interval_custom');
        default:
          return context.tr('interval_monthly');
      }
    }

    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(CupertinoIcons.repeat, size: 16, color: cl.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('repeat_invoice'),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cl.textPrimary,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: CupertinoSwitch(
                    value: isOn,
                    activeTrackColor: kPrimary,
                    onChanged: (val) {
                      invoice.updateRecurringSettings(
                        liveInvoice.invoiceId!,
                        isRecurring: val,
                        interval: liveInvoice.recurringInterval ?? 'monthly',
                        customDays: liveInvoice.recurringCustomDays,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isOn) ...[
            Divider(height: 1, color: cl.border),
            AppTap(
              onTap: () => _showIntervalPicker(liveInvoice, invoice),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar_today,
                      size: 16,
                      color: cl.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('recurring_interval'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: cl.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      intervalLabel(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 13,
                      color: cl.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (nextDate != null) ...[
              Divider(height: 1, color: cl.border),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 16,
                      color: cl.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('recurring_next').replaceAll(
                        '{date}',
                        // nextRecurringDate is stored as yyyy-MM-dd — format for display
                        () {
                          try {
                            return DateFormat(
                              'MMM dd, yyyy',
                            ).format(DateTime.parse(nextDate));
                          } catch (_) {
                            return nextDate;
                          }
                        }(),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: cl.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showIntervalPicker(InvoiceModel liveInvoice, InvoiceProvider invoice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) =>
              _IntervalPickerSheet(liveInvoice: liveInvoice, invoice: invoice),
    );
  }

  // ── Brief toast (works in CupertinoApp without Scaffold) ──────────────────
  void _showToast(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xDD000000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ── Bank detail card (single row, all info together) ──────────────────────
  Widget _bankCard(BankModel bank) {
    final cl = context.colors;
    final hasAccNumber = (bank.accountNumber ?? '').isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimary, Color(0xFF0A5C60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.creditcard,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.bankName ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cl.textPrimary,
                  ),
                ),
                if ((bank.title ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bank.title!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cl.textSecondary,
                    ),
                  ),
                ],
                if (hasAccNumber) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cl.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bank.accountNumber!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable info row ──────────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String label, String value) {
    final cl = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cl.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: kPrimary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: cl.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cl.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── Send as PDF (share via native share sheet) ────────────────────────────
  Future<void> _sendAsPdf(
    TemplatesColorsProvider data,
    InvoiceModel invoice,
  ) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final sym =
          Provider.of<CurrencyProvider>(
            context,
            listen: false,
          ).currency.pdfSymbol;
      final bp = Provider.of<BusinessProvider>(context, listen: false);
      final biz =
          invoice.businessId != null && bp.businesses.isNotEmpty
              ? bp.businesses.firstWhere(
                (b) => b.id == invoice.businessId,
                orElse: () => bp.activeBusiness ?? bp.businesses.first,
              )
              : bp.activeBusiness;
      final pdfData = await PdfService().invoicePdfGenerate(
        invoice,
        data,
        business: biz,
        currencySymbol: sym,
        locale: 'en',
      );
      if (kIsWeb) {
        // No filesystem and no native share sheet on web — trigger a
        // browser download instead.
        await ExportHelper.downloadPdf(
          pdfData,
          'Invoice_${invoice.invoiceId}.pdf',
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final pdfFile = File(
          '${tempDir.path}/Invoice_${invoice.invoiceId}.pdf',
        );
        await pdfFile.writeAsBytes(pdfData);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(pdfFile.path)]),
        );
      }
    } catch (_) {
      if (mounted) _showToast(context.tr('export_failed'));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Send as Image (raster PDF pages → PNG, then share) ────────────────────
  Future<void> _sendAsImage(
    TemplatesColorsProvider data,
    InvoiceModel invoice,
  ) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final sym =
          Provider.of<CurrencyProvider>(
            context,
            listen: false,
          ).currency.pdfSymbol;
      final bp = Provider.of<BusinessProvider>(context, listen: false);
      final biz =
          invoice.businessId != null && bp.businesses.isNotEmpty
              ? bp.businesses.firstWhere(
                (b) => b.id == invoice.businessId,
                orElse: () => bp.activeBusiness ?? bp.businesses.first,
              )
              : bp.activeBusiness;
      final pdfData = await PdfService().invoicePdfGenerate(
        invoice,
        data,
        business: biz,
        currencySymbol: sym,
        locale: 'en',
      );

      if (kIsWeb) {
        // No filesystem on web — rasterize to PNG bytes and download them
        // directly instead of writing to disk.
        final pages = <Uint8List>[];
        await for (final raster in Printing.raster(pdfData, dpi: 200)) {
          pages.add(await raster.toPng());
        }
        if (pages.isNotEmpty) {
          await ExportHelper.downloadImages(
            pages,
            'Invoice_${invoice.invoiceId}',
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final List<XFile> files = [];
      int page = 0;
      await for (final raster in Printing.raster(pdfData, dpi: 200)) {
        final png = await raster.toPng();
        final suffix = page == 0 ? '' : '_p${page + 1}';
        final path = '${tempDir.path}/Invoice_${invoice.invoiceId}$suffix.png';
        await File(path).writeAsBytes(png, flush: true);
        files.add(XFile(path));
        page++;
      }
      if (files.isNotEmpty) {
        await SharePlus.instance.share(ShareParams(files: files));
      }
    } catch (_) {
      if (mounted) _showToast(context.tr('export_failed'));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Format picker (PDF / Image) shown after customize sheet closes ─────────
  void _showSendFormatSheet(
    TemplatesColorsProvider data,
    InvoiceModel invoice,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (_) => CupertinoActionSheet(
            title: Text(context.tr('export_format')),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _sendAsPdf(data, invoice);
                },
                child: Text(context.tr('pdf_document')),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _sendAsImage(data, invoice);
                },
                child: Text(context.tr('image_png')),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
          ),
    );
  }

  // ── Customize invoice sheet (template + color) ────────────────────────────
  void _showCustomizeSheet(
    TemplatesColorsProvider data,
    String applyLabel,
    VoidCallback onApply,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StatefulBuilder(
            builder: (ctx, setSheet) {
              int colorIdx = data.colors.indexOf(data.color);
              if (colorIdx < 0) colorIdx = 0;

              return Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: context.colors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // ── Template section ────────────────────────────────────
                        Text(
                          context.tr('choose_template'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('choose_template_sub'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ctx.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Template grid (2 columns)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                          children:
                              InvoiceTemplate.values.map((t) {
                                final isSelected = data.template == t;
                                return AppTap(
                                  onTap: () {
                                    data.selectTemplate(t);
                                    setSheet(() {});
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      color: context.colors.background,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? data.color
                                                : context.colors.border,
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: data.color.withValues(
                                                    alpha: 0.18,
                                                  ),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(14),
                                                ),
                                            child: _TemplatePreview(
                                              template: t,
                                              color: data.color,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? data.color.withValues(
                                                      alpha: 0.08,
                                                    )
                                                    : ctx.colors.surface,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  bottom: Radius.circular(14),
                                                ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      t.label,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            isSelected
                                                                ? data.color
                                                                : ctx
                                                                    .colors
                                                                    .textPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      t.description,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        color:
                                                            context
                                                                .colors
                                                                .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: BoxDecoration(
                                                    color: data.color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 24),
                        Divider(color: context.colors.border, height: 1),
                        const SizedBox(height: 20),

                        // ── Color section ───────────────────────────────────────
                        Text(
                          context.tr('accent_color'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('accent_color_sub'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ctx.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(data.colors.length, (i) {
                            final isSelected = colorIdx == i;
                            return AppTap(
                              onTap: () {
                                colorIdx = i;
                                data.selectColor(data.colors[i]);
                                setSheet(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: data.colors[i],
                                  shape: BoxShape.circle,
                                  border:
                                      isSelected
                                          ? Border.all(
                                            color: context.colors.textPrimary,
                                            width: 2.5,
                                          )
                                          : Border.all(
                                            color: Colors.transparent,
                                            width: 2.5,
                                          ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: data.colors[i].withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                          : null,
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                        : null,
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Apply button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              applyLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    ).then((_) {
      if (!mounted) return;
      onApply();
    });
  }

  // ── Bottom bar: Preview + Send ─────────────────────────────────────────────
  Widget _buildBottomBar(
    TemplatesColorsProvider data,
    InvoiceProvider invoice,
    InvoiceModel liveInvoice,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: context.tr('preview'),
              icon: CupertinoIcons.eye,
              outlined: true,
              onTap:
                  () => _showCustomizeSheet(data, context.tr('apply'), () {
                    Navigation.go(
                      context,
                      InvoicePreviewScreen(
                        invoice: liveInvoice,
                        template: data.template,
                        accentColor: data.color,
                      ),
                    );
                  }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label:
                  _isExporting
                      ? context.tr('opening')
                      : (liveInvoice.documentType == 'Quote'
                          ? context.tr('send_quote')
                          : liveInvoice.documentType == 'Estimate'
                          ? context.tr('send_estimate')
                          : context.tr('send_invoice')),
              icon: CupertinoIcons.paperplane,
              outlined: false,
              onTap:
                  _isExporting
                      ? () {}
                      : () => _showCustomizeSheet(
                        data,
                        context.tr('apply'),
                        () => _showSendFormatSheet(data, liveInvoice),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Interval picker bottom sheet ─────────────────────────────────────────────
class _IntervalPickerSheet extends StatefulWidget {
  final InvoiceModel liveInvoice;
  final InvoiceProvider invoice;

  const _IntervalPickerSheet({
    required this.liveInvoice,
    required this.invoice,
  });

  @override
  State<_IntervalPickerSheet> createState() => _IntervalPickerSheetState();
}

class _IntervalPickerSheetState extends State<_IntervalPickerSheet> {
  late final TextEditingController _customDaysCtrl;
  late String _selectedInterval;
  int? _customDays;

  @override
  void initState() {
    super.initState();
    _selectedInterval = widget.liveInvoice.recurringInterval ?? 'monthly';
    _customDays = widget.liveInvoice.recurringCustomDays;
    _customDaysCtrl = TextEditingController(
      text: widget.liveInvoice.recurringCustomDays?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _customDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    final options = [
      ('weekly', context.tr('interval_weekly')),
      ('monthly', context.tr('interval_monthly')),
      ('custom', context.tr('interval_custom')),
    ];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('recurring_interval'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cl.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((entry) {
                final isSelected = _selectedInterval == entry.$1;
                return AppTap(
                  onTap:
                      () => setState(() {
                        _selectedInterval = entry.$1;
                        if (entry.$1 != 'custom') _customDays = null;
                      }),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.$2,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: isSelected ? kPrimary : cl.textPrimary,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          color: isSelected ? kPrimary : cl.textHint,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (_selectedInterval == 'custom')
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: TextField(
                    controller: _customDaysCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: cl.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('custom_days_hint'),
                      hintStyle: GoogleFonts.poppins(color: cl.textHint),
                      suffixText: context.tr('custom_days_unit'),
                      filled: true,
                      fillColor: cl.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cl.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cl.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: kPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (v) => _customDays = int.tryParse(v),
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Require a valid day count before saving custom interval
                      if (_selectedInterval == 'custom' &&
                          (_customDays == null || _customDays! <= 0)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('custom_days_required')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      widget.invoice.updateRecurringSettings(
                        widget.liveInvoice.invoiceId!,
                        isRecurring: true,
                        interval: _selectedInterval,
                        customDays:
                            _selectedInterval == 'custom' ? _customDays : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('save'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Template mini-preview widget ─────────────────────────────────────────────
class _TemplatePreview extends StatelessWidget {
  final InvoiceTemplate template;
  final Color color;

  const _TemplatePreview({required this.template, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white, child: _buildPreview());
  }

  Widget _buildPreview() {
    switch (template) {
      case InvoiceTemplate.classic:
        return _classicPreview();
      case InvoiceTemplate.elegant:
        return _elegantPreview();
      case InvoiceTemplate.minimal:
        return _minimalPreview();
      case InvoiceTemplate.wave:
        return _wavePreview();
      case InvoiceTemplate.boutique:
        return _boutiquePreview();
      case InvoiceTemplate.geometric:
        return _geometricPreview();
    }
  }

  // Classic: full-width colored header band
  Widget _classicPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          color: color,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _fakeLine(width: 40, color: Colors.white, height: 5),
                  const SizedBox(height: 3),
                  _fakeLine(
                    width: 24,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 3,
                  ),
                ],
              ),
              _fakeLine(width: 30, color: Colors.white, height: 7),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fakeLine(width: 50, color: Colors.grey.shade300, height: 4),
              const SizedBox(height: 6),
              _fakeTable(color),
            ],
          ),
        ),
      ],
    );
  }

  // Elegant: very dark header + colored accent stripe
  Widget _elegantPreview() {
    final dark = Color.lerp(color, Colors.black, 0.75)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: dark,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _fakeLine(width: 40, color: Colors.white, height: 5),
                  const SizedBox(height: 3),
                  _fakeLine(
                    width: 24,
                    color: Colors.white.withValues(alpha: 0.4),
                    height: 3,
                  ),
                ],
              ),
              _fakeLine(width: 30, color: color, height: 7),
            ],
          ),
        ),
        Container(height: 2.5, color: color),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 2.5, height: 20, color: color),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fakeLine(
                        width: 36,
                        color: Colors.grey.shade700,
                        height: 5,
                      ),
                      const SizedBox(height: 3),
                      _fakeLine(
                        width: 24,
                        color: Colors.grey.shade400,
                        height: 3,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _fakeTableElegant(dark, color),
            ],
          ),
        ),
      ],
    );
  }

  // Minimal: thin top stripe, plain header, line-only table
  Widget _minimalPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 3, color: color),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fakeLine(
                        width: 44,
                        color: Colors.grey.shade800,
                        height: 6,
                      ),
                      const SizedBox(height: 3),
                      _fakeLine(width: 24, color: color, height: 3),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _fakeLine(
                        width: 28,
                        color: Colors.grey.shade400,
                        height: 3,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: color, width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: _fakeLine(width: 16, color: color, height: 3),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade300, height: 1, thickness: 0.5),
              const SizedBox(height: 8),
              _fakeTableMinimal(color),
            ],
          ),
        ),
      ],
    );
  }

  // Wave: curved arch header with accent fill
  Widget _wavePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 52,
          child: ClipRect(
            child: CustomPaint(
              painter: _WaveHeaderPainter(color),
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 8, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fakeLine(width: 40, color: Colors.white, height: 5),
                        const SizedBox(height: 3),
                        _fakeLine(
                          width: 24,
                          color: Colors.white.withValues(alpha: 0.6),
                          height: 3,
                        ),
                      ],
                    ),
                    _fakeLine(width: 28, color: Colors.white, height: 7),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fakeLine(width: 50, color: Colors.grey.shade300, height: 4),
              const SizedBox(height: 6),
              _fakeTable(color),
            ],
          ),
        ),
      ],
    );
  }

  // Geometric: white bg · dual-color corner triangles · "INVOICE" title · 5-col bordered table
  Widget _geometricPreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _GeometricCornersPainter(color, color)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large "INVOICE" title
              _fakeLine(width: 44, color: const Color(0xFF1F2B3A), height: 8),
              const SizedBox(height: 10),
              // Meta row: [Date Issued / Invoice No] — [Issued To / Client]
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fakeLine(
                        width: 24,
                        color: Colors.grey.shade700,
                        height: 3,
                      ),
                      const SizedBox(height: 2),
                      _fakeLine(
                        width: 18,
                        color: Colors.grey.shade400,
                        height: 2,
                      ),
                      const SizedBox(height: 4),
                      _fakeLine(
                        width: 22,
                        color: Colors.grey.shade700,
                        height: 3,
                      ),
                      const SizedBox(height: 2),
                      _fakeLine(
                        width: 14,
                        color: Colors.grey.shade400,
                        height: 2,
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fakeLine(
                        width: 20,
                        color: Colors.grey.shade700,
                        height: 3,
                      ),
                      const SizedBox(height: 2),
                      _fakeLine(
                        width: 28,
                        color: Colors.grey.shade400,
                        height: 2,
                      ),
                      const SizedBox(height: 2),
                      _fakeLine(
                        width: 24,
                        color: Colors.grey.shade400,
                        height: 2,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _fakeTableGeometric(color),
            ],
          ),
        ),
      ],
    );
  }

  // 5-col table matching PDF: No · Description · Qty · Unit Price · Subtotal
  Widget _fakeTableGeometric(Color accent) {
    final border = Border.all(color: const Color(0xFFD0D0D0), width: 0.5);
    const headerBg = Color(0xFFF2F2F2);

    // Header row: 5 columns proportional to PDF (0.8 : 4.0 : 1.2 : 2.0 : 2.0)
    Widget headerRow() => Container(
      height: 13,
      decoration: BoxDecoration(color: headerBg, border: border),
      child: Row(
        children: [
          _tableCell(flex: 1, color: Colors.grey.shade600),
          _tableCell(flex: 4, color: Colors.grey.shade600),
          _tableCell(flex: 1, color: Colors.grey.shade600),
          _tableCell(flex: 2, color: Colors.grey.shade600),
          _tableCell(flex: 2, color: Colors.grey.shade600),
        ],
      ),
    );

    // Data row: 5 columns, full border, white bg
    Widget dataRow() => Container(
      height: 11,
      decoration: BoxDecoration(color: Colors.white, border: border),
      child: Row(
        children: [
          Expanded(flex: 1, child: const SizedBox()),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(height: 2.5, color: Colors.grey.shade300),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 6,
                height: 2.5,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 14,
                height: 2.5,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 14,
                height: 2.5,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );

    // Grand total row: label + accent-colored amount in last two cells
    Widget totalRow() => Container(
      height: 12,
      decoration: BoxDecoration(color: Colors.white, border: border),
      child: Row(
        children: [
          const Spacer(flex: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(height: 2.5, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(height: 3, color: accent),
            ),
          ),
        ],
      ),
    );

    return Column(children: [headerRow(), dataRow(), dataRow(), totalRow()]);
  }

  // Boutique: white bg · dark badge logo · large "INVOICE" title · clean table
  Widget _boutiquePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2B3A),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  _fakeLine(width: 30, color: Colors.grey.shade700, height: 4),
                ],
              ),
              _fakeLine(width: 34, color: const Color(0xFF1F2B3A), height: 7),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fakeLine(width: 46, color: Colors.grey.shade300, height: 4),
              const SizedBox(height: 6),
              _fakeTableBoutique(color),
            ],
          ),
        ),
      ],
    );
  }

  // 4-col (Description · Qty · Unit Price · Amount) + accent-bg total row
  Widget _fakeTableBoutique(Color accent) {
    return Column(
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 0.8),
              bottom: BorderSide(color: Colors.grey.shade300, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              _tableCell(flex: 5, color: Colors.grey.shade400),
              _tableCell(flex: 1, color: Colors.grey.shade400),
              _tableCell(flex: 2, color: Colors.grey.shade400),
              _tableCell(flex: 2, color: Colors.grey.shade400),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
        // Grand total: accent bg + white label/value (matches PDF)
        Container(
          height: 12,
          color: accent,
          child: Row(
            children: [
              const Spacer(flex: 6),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: 3,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(height: 3, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fakeLine({
    required double width,
    required Color color,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // 4-col (Description · Qty · Unit Price · Subtotal) + accent-bg total row
  Widget _fakeTable(Color accent) {
    return Column(
      children: [
        Container(
          height: 14,
          color: accent,
          child: Row(
            children: [
              _tableCell(flex: 5, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 1, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 2, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 2, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(const Color(0xFFF1F5F9)),
        // Grand total: accent bg + white label/value (matches classic/wave PDF)
        Container(
          height: 12,
          color: accent,
          child: Row(
            children: [
              const Spacer(flex: 6),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: 3,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(height: 3, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4-col (Description · Qty · Unit Price · Subtotal) + accent-text total row
  Widget _fakeTableElegant(Color dark, Color accent) {
    return Column(
      children: [
        Container(
          height: 14,
          color: dark,
          child: Row(
            children: [
              _tableCell(flex: 5, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 1, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 2, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 2, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
        // Grand total: dark label + accent-colored value (matches elegant PDF)
        Container(
          height: 12,
          color: Colors.white,
          child: Row(
            children: [
              const Spacer(flex: 6),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(height: 3, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(height: 3, color: accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4-col (Description · Qty · Unit Price · Subtotal) + accent-text total row
  Widget _fakeTableMinimal(Color accent) {
    return Column(
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: accent, width: 1.5),
              bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              _tableCell(flex: 5, color: Colors.grey.shade400),
              _tableCell(flex: 1, color: Colors.grey.shade400),
              _tableCell(flex: 2, color: Colors.grey.shade400),
              _tableCell(flex: 2, color: Colors.grey.shade400),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
        // Grand total: grey divider above, dark label + accent value (matches minimal PDF)
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Spacer(flex: 6),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(height: 3, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(height: 3, color: accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCell({required int flex, required Color color}) {
    return Expanded(
      flex: flex,
      child: Center(child: Container(width: 20, height: 3, color: color)),
    );
  }

  // 4-col data row: Description · Qty · Unit Price · Subtotal (flex 5:1:2:2)
  Widget _fakeRow(Color bg) {
    return Container(
      height: 12,
      color: bg,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(height: 3, color: Colors.grey.shade300),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 8,
                height: 3,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 12,
                height: 3,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 14,
                height: 3,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Geometric corner rectangles painter for template preview ──────────────────
class _GeometricCornersPainter extends CustomPainter {
  final Color accent;
  final Color secondary;
  _GeometricCornersPainter(this.accent, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pink = Color(0xFFF4A7A3);

    // White background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);

    // Top-right: large teal triangle (behind)
    canvas.drawPath(
      Path()
        ..moveTo(w, 0)
        ..lineTo(w - 60, 0)
        ..lineTo(w, 60)
        ..close(),
      Paint()..color = accent,
    );
    // Top-right: small pink triangle (on top, at corner)
    canvas.drawPath(
      Path()
        ..moveTo(w, 0)
        ..lineTo(w - 26, 0)
        ..lineTo(w, 26)
        ..close(),
      Paint()..color = pink,
    );

    // Bottom-left: large teal triangle (behind)
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(60, h)
        ..lineTo(0, h - 60)
        ..close(),
      Paint()..color = accent,
    );
    // Bottom-left: small pink triangle (on top, at corner)
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(26, h)
        ..lineTo(0, h - 26)
        ..close(),
      Paint()..color = pink,
    );
  }

  @override
  bool shouldRepaint(_GeometricCornersPainter old) =>
      old.accent != accent || old.secondary != secondary;
}

// ── Wave header painter for template preview ─────────────────────────────────
class _WaveHeaderPainter extends CustomPainter {
  final Color color;
  const _WaveHeaderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path =
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height - 10)
          ..quadraticBezierTo(
            size.width * 0.5,
            size.height + 6,
            0,
            size.height - 10,
          )
          ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveHeaderPainter old) => old.color != color;
}

// ── Action button (shared by Preview + Send) ──────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child:
          outlined
              ? OutlinedButton.icon(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPrimary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(CupertinoIcons.eye, size: 18, color: kPrimary),
                label: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              )
              : ElevatedButton.icon(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(icon, size: 18, color: Colors.white),
                label: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
    );
  }
}
