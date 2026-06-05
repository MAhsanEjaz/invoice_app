import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/pdf/pdf_service.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/screens/home_screen.dart';
import 'package:invoicemaker/screens/new_invoice_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/business_provider.dart';
import '../providers/pdf_templates_colors_provider.dart';

class VerificationInvoice extends StatefulWidget {
  final ClientModel? clientModel;
  final ItemModel? itemModel;
  final InvoiceModel? invoiceModel;

  const VerificationInvoice({
    super.key,
    this.itemModel,
    this.clientModel,
    this.invoiceModel,
  });

  @override
  State<VerificationInvoice> createState() => _VerificationInvoiceState();
}

class _VerificationInvoiceState extends State<VerificationInvoice> {
  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // ── Received-amount dialog ─────────────────────────────────────────────────
  void _showReceivedDialog(InvoiceProvider invoice, double current) {
    final ctrl = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(2) : '',
    );

    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Received Amount',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: '0.00',
            autofocus: true,
            style: GoogleFonts.poppins(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: CupertinoColors.systemBlue),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final amount = double.tryParse(ctrl.text.trim()) ?? 0;
              invoice.updateReceivedAmount(
                widget.invoiceModel!.invoiceId!,
                amount,
              );
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Discount dialog ────────────────────────────────────────────────────────
  void _showDiscountDialog(InvoiceProvider invoice, double current) {
    final ctrl = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(2) : '',
    );

    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Discount Amount',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            placeholder: '0.00',
            autofocus: true,
            style: GoogleFonts.poppins(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: CupertinoColors.systemBlue),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final amount = double.tryParse(ctrl.text.trim()) ?? 0;
              invoice.updateDiscount(
                widget.invoiceModel!.invoiceId!,
                amount,
              );
              Navigator.pop(context);
            },
            child: Text(
              'Apply',
              style: GoogleFonts.poppins(
                color: kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────────
  void _confirmDelete(InvoiceProvider invoice) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'Delete Invoice',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Invoice #${widget.invoiceModel!.invoiceId} will be permanently deleted. This cannot be undone.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
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
              'Delete',
              style: GoogleFonts.poppins(color: CupertinoColors.systemRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoice, _) {
        // ── Always read the live invoice so edits are reflected immediately ──
        final liveInvoice = invoice.invoice.firstWhere(
          (e) => e.invoiceId == widget.invoiceModel!.invoiceId,
          orElse: () => widget.invoiceModel!,
        );

        final isPaid = liveInvoice.invoiceStatus == 'Paid';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goHome();
          },
          child: CupertinoPageScaffold(
            backgroundColor: context.colors.background,
            child: Column(
              children: [
                _buildNavBar(liveInvoice, invoice),
                Expanded(child: _buildBody(liveInvoice, isPaid, invoice)),
                Consumer<TemplatesColorsProvider>(
                  builder: (ctx, data, _) =>
                      _buildBottomBar(data, invoice, liveInvoice),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Nav bar ────────────────────────────────────────────────────────────────
  Widget _buildNavBar(InvoiceModel liveInvoice, InvoiceProvider invoice) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Back to home
            GestureDetector(
              onTap: _goHome,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.xmark, color: kPrimary, size: 15),
              ),
            ),

            const Spacer(),
            Text(
              'Invoice #${liveInvoice.invoiceId}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const Spacer(),

            // Edit
            GestureDetector(
              onTap: () => Navigation.go(
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
                child: const Icon(CupertinoIcons.pencil, color: kPrimary, size: 15),
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
    InvoiceProvider invoice,
  ) {
    final sym = Provider.of<CurrencyProvider>(context).symbol;
    // All values derived from the live provider object
    final items = liveInvoice.items ?? [];
    final subtotal = items.fold<double>(
      0,
      (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1)),
    );
    final discount = liveInvoice.discount ?? 0;
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final received = liveInvoice.receivedAmount ?? 0;
    final balanceDue = (total - received).clamp(0.0, double.infinity);

    final client = (liveInvoice.clients?.isNotEmpty ?? false)
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
            decoration: context.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    statusBadge(context, isPaid),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          liveInvoice.date ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        if (liveInvoice.dueDate?.isNotEmpty ?? false)
                          Text(
                            'Due: ${liveInvoice.dueDate}',
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
                const SizedBox(height: 14),
                Text(
                  '$sym${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  clientName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Client ────────────────────────────────────────────────────────
          const SizedBox(height: 20),
          sectionLabel(context, 'Client'),
          Container(
            decoration: context.cardDecoration,
            child: Column(
              children: [
                _infoRow(CupertinoIcons.person, 'Name', clientName),
                if (clientEmail.isNotEmpty) ...[
                  Divider(height: 1, color: context.colors.border),
                  _infoRow(CupertinoIcons.mail, 'Email', clientEmail),
                ],
                if (clientPhone.isNotEmpty) ...[
                  Divider(height: 1, color: context.colors.border),
                  _infoRow(CupertinoIcons.phone, 'Phone', clientPhone),
                ],
                if (clientAddress.isNotEmpty) ...[
                  Divider(height: 1, color: context.colors.border),
                  _infoRow(
                    CupertinoIcons.location,
                    'Address',
                    clientAddress,
                  ),
                ],
              ],
            ),
          ),

          // ── Items ─────────────────────────────────────────────────────────
          const SizedBox(height: 20),
          sectionLabel(context, 'Items'),
          Container(
            decoration: context.cardDecoration,
            child: Column(
              children: [
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: context.colors.border),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final lineTotal =
                        ((item.price ?? 0) * (item.qty ?? 1)).toStringAsFixed(2);
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
                                Text(
                                  '${item.qty} × $sym${item.price}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$sym$lineTotal',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
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
                        'Subtotal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$sym${subtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Discount row — always visible and tappable
                Divider(height: 1, color: context.colors.border),
                GestureDetector(
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
                          color: discount > 0 ? kDangerColor : context.colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Discount',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                discount > 0 ? kDangerColor : context.colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          discount > 0
                              ? '-$sym${discount.toStringAsFixed(2)}'
                              : '$sym${0.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                discount > 0 ? kDangerColor : context.colors.textPrimary,
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

                // Total row — shown only when discount is applied
                if (discount > 0) ...[
                  Divider(height: 1, color: context.colors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$sym${total.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
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
            sectionLabel(context, 'Notes'),
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
            sectionLabel(context, 'Terms & Conditions'),
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
          if (liveInvoice.bank != null) ...[
            const SizedBox(height: 20),
            sectionLabel(context, 'Payment Details'),
            Container(
              decoration: context.cardDecoration,
              child: Column(
                children: [
                  _infoRow(
                    CupertinoIcons.creditcard,
                    'Bank',
                    liveInvoice.bank!.bankName ?? '',
                  ),
                  Divider(height: 1, color: context.colors.border),
                  _infoRow(
                    CupertinoIcons.person,
                    'Account Title',
                    liveInvoice.bank!.title ?? '',
                  ),
                  if ((liveInvoice.bank!.accountNumber ?? '').isNotEmpty) ...[
                    Divider(height: 1, color: context.colors.border),
                    _infoRow(
                      CupertinoIcons.number,
                      'Account No.',
                      liveInvoice.bank!.accountNumber!,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Payment ───────────────────────────────────────────────────────
          const SizedBox(height: 20),
          sectionLabel(context, 'Payment'),
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
                        'Mark as Paid',
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
                GestureDetector(
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
                          'Received',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$sym${received.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: received > 0 ? kPaidColor : context.colors.textPrimary,
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
                          'Balance Due',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kUnpaidColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$sym${balanceDue.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kUnpaidColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Delete invoice ─────────────────────────────────────────────────
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _confirmDelete(invoice),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.dangerBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kDangerColor.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                    'Delete Invoice',
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

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Reusable info row ──────────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String label, String value) {
    final cl = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cl.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: cl.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
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
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          int colorIdx = data.colors.indexOf(data.color);
          if (colorIdx < 0) colorIdx = 0;

          return Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      'Choose Template',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a layout for your PDF invoice',
                      style: GoogleFonts.poppins(fontSize: 12, color: ctx.colors.textSecondary),
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
                      children: InvoiceTemplate.values.map((t) {
                        final isSelected = data.template == t;
                        return GestureDetector(
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
                                color: isSelected ? data.color : context.colors.border,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: data.color.withValues(alpha: 0.18),
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
                                    borderRadius: const BorderRadius.vertical(
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
                                    color: isSelected
                                        ? data.color.withValues(alpha: 0.08)
                                        : ctx.colors.surface,
                                    borderRadius: const BorderRadius.vertical(
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
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? data.color
                                                    : ctx.colors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              t.description,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: context.colors.textSecondary,
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
                      'Accent Color',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applied to the header and highlights',
                      style: GoogleFonts.poppins(fontSize: 12, color: ctx.colors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(data.colors.length, (i) {
                        final isSelected = colorIdx == i;
                        return GestureDetector(
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
                              border: isSelected
                                  ? Border.all(color: context.colors.textPrimary, width: 2.5)
                                  : Border.all(
                                      color: Colors.transparent, width: 2.5),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: data.colors[i]
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
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
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Preview',
              icon: CupertinoIcons.eye,
              outlined: true,
              onTap: () => _showCustomizeSheet(data, 'Apply & Preview', () {
                Navigation.go(
                  context,
                  PdfInvoiceScreen(invoice: liveInvoice, provider: data),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'Send Invoice',
              icon: CupertinoIcons.paperplane,
              outlined: false,
              onTap: () => _showCustomizeSheet(data, 'Apply & Send', () async {
                final sym = Provider.of<CurrencyProvider>(context, listen: false)
                    .currency
                    .pdfSymbol;
                final bp = Provider.of<BusinessProvider>(context, listen: false);
                final biz = liveInvoice.businessId != null && bp.businesses.isNotEmpty
                    ? bp.businesses.firstWhere(
                        (b) => b.id == liveInvoice.businessId,
                        orElse: () => bp.activeBusiness ?? bp.businesses.first,
                      )
                    : bp.activeBusiness;
                final pdfData = await PdfService().invoicePdfGenerate(
                  liveInvoice,
                  data,
                  business: biz,
                  currencySymbol: sym,
                );
                final tempDir = await getTemporaryDirectory();
                final pdfFile = File('${tempDir.path}/Invoice_${liveInvoice.invoiceId}.pdf');
                await pdfFile.writeAsBytes(pdfData);
                await OpenFile.open(pdfFile.path);
              }),
            ),
          ),
        ],
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
    return Container(
      color: Colors.white,
      child: _buildPreview(),
    );
  }

  Widget _buildPreview() {
    switch (template) {
      case InvoiceTemplate.classic:
        return _classicPreview();
      case InvoiceTemplate.modern:
        return _modernPreview();
      case InvoiceTemplate.elegant:
        return _elegantPreview();
      case InvoiceTemplate.minimal:
        return _minimalPreview();
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
                  _fakeLine(width: 24, color: Colors.white.withValues(alpha: 0.6), height: 3),
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

  // Modern: white left + colored right split header
  Widget _modernPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 10, top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fakeLine(width: 44, color: Colors.grey.shade800, height: 6),
                      const SizedBox(height: 4),
                      Container(width: 18, height: 2, color: color),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  color: color,
                  padding: const EdgeInsets.only(right: 8, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _fakeLine(width: 36, color: Colors.white, height: 7),
                      const SizedBox(height: 5),
                      _fakeLine(width: 24, color: Colors.white.withValues(alpha: 0.6), height: 3),
                    ],
                  ),
                ),
              ),
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
              _fakeTableModern(color),
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
                  _fakeLine(width: 24, color: Colors.white.withValues(alpha: 0.4), height: 3),
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
                      _fakeLine(width: 36, color: Colors.grey.shade700, height: 5),
                      const SizedBox(height: 3),
                      _fakeLine(width: 24, color: Colors.grey.shade400, height: 3),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _fakeTableElegant(dark),
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
                      _fakeLine(width: 44, color: Colors.grey.shade800, height: 6),
                      const SizedBox(height: 3),
                      _fakeLine(width: 24, color: color, height: 3),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _fakeLine(width: 28, color: Colors.grey.shade400, height: 3),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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

  Widget _fakeLine({required double width, required Color color, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _fakeTable(Color accent) {
    return Column(
      children: [
        Container(
          height: 14,
          color: accent,
          child: Row(
            children: [
              _tableCell(flex: 4, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 1, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 2, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(const Color(0xFFF1F5F9)),
        _fakeRow(Colors.white),
      ],
    );
  }

  Widget _fakeTableModern(Color accent) {
    return Column(
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: accent, width: 1.5)),
          ),
          child: Row(
            children: [
              _tableCell(flex: 4, color: accent.withValues(alpha: 0.6)),
              _tableCell(flex: 1, color: accent.withValues(alpha: 0.6)),
              _tableCell(flex: 2, color: accent.withValues(alpha: 0.6)),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
      ],
    );
  }

  Widget _fakeTableElegant(Color dark) {
    return Column(
      children: [
        Container(
          height: 14,
          color: dark,
          child: Row(
            children: [
              _tableCell(flex: 4, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 1, color: Colors.white.withValues(alpha: 0.7)),
              _tableCell(flex: 2, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
      ],
    );
  }

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
              _tableCell(flex: 4, color: Colors.grey.shade400),
              _tableCell(flex: 1, color: Colors.grey.shade400),
              _tableCell(flex: 2, color: Colors.grey.shade400),
            ],
          ),
        ),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
        _fakeRow(Colors.white),
      ],
    );
  }

  Widget _tableCell({required int flex, required Color color}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Container(width: 20, height: 3, color: color),
      ),
    );
  }

  Widget _fakeRow(Color bg) {
    return Container(
      height: 12,
      color: bg,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(height: 3, color: Colors.grey.shade300),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(child: Container(width: 8, height: 3, color: Colors.grey.shade300)),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(height: 3, color: Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }
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
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(icon, size: 18, color: context.colors.textPrimary),
              label: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
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
