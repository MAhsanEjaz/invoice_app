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
  int _selectedColorIndex = 0;

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
            backgroundColor: kBackground,
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
                decoration: const BoxDecoration(
                  color: kPrimaryLight,
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
                color: kTextPrimary,
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
                decoration: const BoxDecoration(
                  color: kPrimaryLight,
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
            decoration: kCardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    statusBadge(isPaid),
                    const Spacer(),
                    Text(
                      liveInvoice.date ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$sym${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  clientName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Client ────────────────────────────────────────────────────────
          const SizedBox(height: 20),
          sectionLabel('Client'),
          Container(
            decoration: kCardDecoration,
            child: Column(
              children: [
                _infoRow(CupertinoIcons.person, 'Name', clientName),
                if (clientEmail.isNotEmpty) ...[
                  const Divider(height: 1, color: kBorder),
                  _infoRow(CupertinoIcons.mail, 'Email', clientEmail),
                ],
                if (clientPhone.isNotEmpty) ...[
                  const Divider(height: 1, color: kBorder),
                  _infoRow(CupertinoIcons.phone, 'Phone', clientPhone),
                ],
                if (clientAddress.isNotEmpty) ...[
                  const Divider(height: 1, color: kBorder),
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
          sectionLabel('Items'),
          Container(
            decoration: kCardDecoration,
            child: Column(
              children: [
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: kBorder),
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
                                    color: kTextPrimary,
                                  ),
                                ),
                                Text(
                                  '${item.qty} × $sym${item.price}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: kTextSecondary,
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
                              color: kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Subtotal row
                const Divider(height: 1, color: kBorder),
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
                          color: kTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$sym${subtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Discount row — always visible and tappable
                const Divider(height: 1, color: kBorder),
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
                          color: discount > 0 ? kDangerColor : kTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Discount',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                discount > 0 ? kDangerColor : kTextSecondary,
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
                                discount > 0 ? kDangerColor : kTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.pencil,
                          size: 13,
                          color: kTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Total row — shown only when discount is applied
                if (discount > 0) ...[
                  const Divider(height: 1, color: kBorder),
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
                            color: kTextSecondary,
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
            sectionLabel('Notes'),
            Container(
              width: double.infinity,
              decoration: kCardDecoration,
              padding: const EdgeInsets.all(16),
              child: Text(
                liveInvoice.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: kTextPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── Payment ───────────────────────────────────────────────────────
          const SizedBox(height: 20),
          sectionLabel('Payment'),
          Container(
            decoration: kCardDecoration,
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
                          color: kTextPrimary,
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

                const Divider(height: 1, color: kBorder),

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
                          color: kTextSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Received',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: kTextSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$sym${received.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: received > 0 ? kPaidColor : kTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          CupertinoIcons.pencil,
                          size: 14,
                          color: kTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Balance Due (only shown when not fully paid)
                if (balanceDue > 0) ...[
                  const Divider(height: 1, color: kBorder),
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
                color: kDangerBg,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kTextSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: kTextSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar: color picker → Preview + Send ──────────────────────────────
  Widget _buildBottomBar(
    TemplatesColorsProvider data,
    InvoiceProvider invoice,
    InvoiceModel liveInvoice,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          // Preview (opens color picker first)
          Expanded(
            child: _ActionButton(
              label: 'Preview',
              icon: CupertinoIcons.eye,
              outlined: true,
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: kSurface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => StatefulBuilder(
                    builder: (ctx, setstate) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: kBorder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Text(
                            'Invoice Color Theme',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Applied to the header and table of your PDF',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.colors.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemBuilder: (_, i) {
                              final isSelected = _selectedColorIndex == i;
                              return GestureDetector(
                                onTap: () {
                                  _selectedColorIndex = i;
                                  data.selectColor(data.colors[i]);
                                  setstate(() {});
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: data.colors[i],
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: kTextPrimary,
                                            width: 2.5,
                                          )
                                        : null,
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
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
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
                                'Apply & Preview',
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
                ).then((_) {
                  if (!mounted) return;
                  Navigation.go(
                    context,
                    PdfInvoiceScreen(invoice: liveInvoice, provider: data),
                  );
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Send Invoice
          Expanded(
            child: _ActionButton(
              label: 'Send Invoice',
              icon: CupertinoIcons.paperplane,
              outlined: false,
              onTap: () async {
                final sym = Provider.of<CurrencyProvider>(context, listen: false)
                    .currency
                    .pdfSymbol;
                final pdfData = await PdfService().invoicePdfGenerate(
                  liveInvoice,
                  data,
                  currencySymbol: sym,
                );
                final tempDir = await getTemporaryDirectory();
                final pdfFile = File('${tempDir.path}/Ledger.pdf');
                await pdfFile.writeAsBytes(pdfData);
                await OpenFile.open(pdfFile.path);
              },
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
                side: const BorderSide(color: kBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(icon, size: 18, color: kTextPrimary),
              label: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
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
