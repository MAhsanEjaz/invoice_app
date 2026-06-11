import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:provider/provider.dart';

// ── Shared palette ────────────────────────────────────────────────────────────
const _classicNavy  = Color(0xFF0F1726);
const _elegantDark  = Color(0xFF111826);
const _rowAlt       = Color(0xFFF8FAFD);
const _borderGrey   = Color(0xFFE1E5EB);
const _textDark     = Color(0xFF1F2B3A);
const _textMid      = Color(0xFF6C7A8D);
const _textMuted    = Color(0xFF9DAABB);

class InvoicePreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;
  final InvoiceTemplate template;
  final Color accentColor;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    required this.template,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BusinessProvider>(context, listen: false);
    BusinessModel? business;
    if (invoice.businessId != null && bp.businesses.isNotEmpty) {
      try {
        business = bp.businesses.firstWhere((b) => b.id == invoice.businessId);
      } catch (_) {
        business = bp.activeBusiness;
      }
    }
    business ??= bp.activeBusiness;

    final currencySymbol =
        Provider.of<CurrencyProvider>(context, listen: false).symbol;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF4B5563),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.xmark,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    context.tr('invoice_preview'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 34),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _InvoiceDocument(
                  invoice: invoice,
                  business: business,
                  currencySymbol: currencySymbol,
                  template: template,
                  accentColor: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invoice document as Flutter widgets ──────────────────────────────────────
class _InvoiceDocument extends StatelessWidget {
  final InvoiceModel invoice;
  final BusinessModel? business;
  final String currencySymbol;
  final InvoiceTemplate template;
  final Color accentColor;

  const _InvoiceDocument({
    required this.invoice,
    required this.business,
    required this.currencySymbol,
    required this.template,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = invoice.items ?? [];
    final subtotal =
        items.fold<double>(0, (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1)));
    final discount = invoice.discount ?? 0;
    final received = invoice.receivedAmount ?? 0;
    final client =
        (invoice.clients?.isNotEmpty ?? false) ? invoice.clients!.first : null;

    final docType = invoice.documentType ?? 'Invoice';
    final docTitle = docType == 'Quote'
        ? context.tr('pdf_quote')
        : docType == 'Estimate'
            ? context.tr('pdf_estimate')
            : context.tr('pdf_invoice');
    final docNoLabel = docType == 'Quote'
        ? context.tr('quote_no')
        : docType == 'Estimate'
            ? context.tr('estimate_no')
            : context.tr('pdf_invoice_no');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, docTitle, docNoLabel),
        if (template == InvoiceTemplate.wave)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildWaveInfoCards(context),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBillFrom(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildBillTo(context, client)),
                ],
              ),
              const SizedBox(height: 20),
              _buildItemsTable(context, items),
              const SizedBox(height: 16),
              _buildTotals(context, subtotal, discount, received),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 20),
                _buildNotes(context),
              ],
              const SizedBox(height: 28),
              _buildFooter(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // ── Route to template ────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, String docTitle, String docNoLabel) {
    switch (template) {
      case InvoiceTemplate.classic:
        return _classicHeader(context, docTitle, docNoLabel);
      case InvoiceTemplate.elegant:
        return _elegantHeader(context, docTitle, docNoLabel);
      case InvoiceTemplate.minimal:
        return _minimalHeader(context, docTitle, docNoLabel);
      case InvoiceTemplate.wave:
        return _waveHeader(context, docTitle, docNoLabel);
      case InvoiceTemplate.boutique:
        return _boutiqueHeader(context, docTitle, docNoLabel);
      case InvoiceTemplate.geometric:
        return _geometricHeader(context, docTitle, docNoLabel);
    }
  }

  // ── CLASSIC ──────────────────────────────────────────────────────────────
  Widget _classicHeader(
      BuildContext context, String docTitle, String docNoLabel) {
    final navyLight = const Color(0xFF243052);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _classicNavy,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (business?.businessLogo != null) ...[
                      _logoWidget(56, rounded: true, whiteBg: true),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business?.businessName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: navyLight,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$docNoLabel${invoice.invoiceId ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
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
              ),
              const SizedBox(width: 12),
              // Right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    docTitle.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (invoice.date?.isNotEmpty ?? false)
                    _classicMetaLine(context.tr('pdf_date'), invoice.date!),
                  if (invoice.dueDate?.isNotEmpty ?? false)
                    _classicMetaLine(context.tr('pdf_due'), invoice.dueDate!),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _statusText(context).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 4, color: accentColor),
      ],
    );
  }

  Widget _classicMetaLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$label  ',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: _textMuted)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }

  // ── ELEGANT ──────────────────────────────────────────────────────────────
  Widget _elegantHeader(
      BuildContext context, String docTitle, String docNoLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: _elegantDark,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (business?.businessLogo != null) ...[
                      _logoWidget(52, rounded: true,
                          borderColor: const Color(0xFF232D45)),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business?.businessName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$docNoLabel${invoice.invoiceId ?? ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF7A8BA0),
                            ),
                          ),
                          if (invoice.date?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${context.tr('pdf_date')}: ${invoice.date!}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF7A8BA0),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right – INVOICE in accent
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    docTitle.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (invoice.dueDate?.isNotEmpty ?? false)
                    Text(
                      '${context.tr('pdf_due')}: ${invoice.dueDate!}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF7A8BA0),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusText(context).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 4, color: accentColor),
      ],
    );
  }

  // ── MINIMAL ──────────────────────────────────────────────────────────────
  Widget _minimalHeader(
      BuildContext context, String docTitle, String docNoLabel) {
    final accentLight = Color.lerp(accentColor, Colors.white, 0.88)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 5, color: accentColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (business?.businessLogo != null) ...[
                      _logoWidget(50, rounded: true),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business?.businessName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$docNoLabel${invoice.invoiceId ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (invoice.date?.isNotEmpty ?? false)
                    Text(
                      invoice.date!,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textMuted),
                    ),
                  if (invoice.dueDate?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('pdf_due')} ${invoice.dueDate!}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusText(context).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _borderGrey),
      ],
    );
  }

  // ── WAVE ─────────────────────────────────────────────────────────────────
  Widget _waveHeader(
      BuildContext context, String docTitle, String docNoLabel) {
    return SizedBox(
      height: 195,
      child: CustomPaint(
        painter: _WaveHeaderPainter(accentColor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 64),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: logo + business name + number pill
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (business?.businessLogo != null) ...[
                      _logoWidget(52, rounded: true, whiteBg: true),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            business?.businessName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$docNoLabel${invoice.invoiceId ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right: document type
              Text(
                docTitle.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BOUTIQUE ──────────────────────────────────────────────────────────────
  Widget _boutiqueHeader(
      BuildContext context, String docTitle, String docNoLabel) {
    final businessName = business?.businessName ?? '';
    final initials = businessName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: badge + business name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _classicNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: business?.businessLogo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(business!.businessLogo!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        initials.isEmpty ? '?' : initials,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Text(
                businessName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
            ],
          ),
          // Right: large document type title
          Text(
            docTitle.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── GEOMETRIC ─────────────────────────────────────────────────────────────
  Widget _geometricHeader(
      BuildContext context, String docTitle, String docNoLabel) {
    final client =
        (invoice.clients?.isNotEmpty ?? false) ? invoice.clients!.first : null;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GeometricBgPainter(accentColor, kPrimary),
          ),
        ),
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "INVOICE" title — right side reserved for corner triangles
              Text(
                docTitle,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: date + invoice no
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('pdf_date_issued')}:',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        invoice.date ?? '',
                        style: const TextStyle(
                            fontSize: 10, color: _textMid),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$docNoLabel:',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${invoice.invoiceId ?? ''}',
                        style: const TextStyle(
                            fontSize: 10, color: _textMid),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                  // Right: issued to
                  if (client != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.tr('pdf_issued_to')}:',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _textDark),
                        ),
                        const SizedBox(height: 2),
                        if ((client.name ?? '').isNotEmpty)
                          Text(client.name!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark)),
                        if ((client.phone ?? '').isNotEmpty)
                          Text(client.phone!,
                              style: const TextStyle(
                                  fontSize: 10, color: _textMid)),
                        if ((client.email ?? '').isNotEmpty)
                          Text(client.email!,
                              style: const TextStyle(
                                  fontSize: 10, color: _textMid)),
                        if ((client.address ?? '').isNotEmpty)
                          Text(client.address!,
                              style: const TextStyle(
                                  fontSize: 10, color: _textMid)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Wave info cards ───────────────────────────────────────────────────────
  Widget _buildWaveInfoCards(BuildContext context) {
    final isInvoice =
        invoice.documentType == null || invoice.documentType == 'Invoice';
    final statusLabel =
        isInvoice ? _statusText(context) : _docTypeLabel(context);
    final isPaid = invoice.invoiceStatus == 'Paid';
    final statusColor =
        isPaid ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final accentLight = Color.lerp(accentColor, Colors.white, 0.90)!;

    Widget card(String label, String value, {bool isStatus = false}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderGrey, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (isStatus && isInvoice)
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(context.tr('pdf_date'),
            invoice.date?.isNotEmpty == true ? invoice.date! : '-'),
        const SizedBox(width: 8),
        card(context.tr('pdf_due'),
            (invoice.dueDate?.isNotEmpty ?? false) ? invoice.dueDate! : '-'),
        const SizedBox(width: 8),
        card(context.tr('pdf_status'), statusLabel, isStatus: true),
      ],
    );
  }

  // ── Bill From ──────────────────────────────────────────────────────────
  Widget _buildBillFrom(BuildContext context) {
    final bank = invoice.bank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.tr('pdf_from')),
        const SizedBox(height: 8),
        Text(
          business?.businessName ?? '',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        if (bank != null) ...[
          const SizedBox(height: 5),
          if ((bank.bankName ?? '').isNotEmpty)
            Text(bank.bankName!,
                style:
                    const TextStyle(fontSize: 10, color: _textMid)),
          if ((bank.title ?? '').isNotEmpty)
            Text(bank.title!,
                style:
                    const TextStyle(fontSize: 10, color: _textMid)),
          if ((bank.accountNumber ?? '').isNotEmpty)
            Text(bank.accountNumber!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                )),
        ],
      ],
    );
  }

  // ── Bill To ───────────────────────────────────────────────────────────
  Widget _buildBillTo(BuildContext context, client) {
    if (client == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.tr('pdf_invoice_to')),
        const SizedBox(height: 8),
        if ((client.name ?? '').isNotEmpty)
          Text(client.name!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textDark,
              )),
        if ((client.email ?? '').isNotEmpty)
          Text(client.email!,
              style: const TextStyle(fontSize: 10, color: _textMid)),
        if ((client.phone ?? '').isNotEmpty)
          Text(client.phone!,
              style: const TextStyle(fontSize: 10, color: _textMid)),
        if ((client.address ?? '').isNotEmpty)
          Text(client.address!,
              style: const TextStyle(fontSize: 10, color: _textMid)),
      ],
    );
  }

  // ── Items table ────────────────────────────────────────────────────────
  Widget _buildItemsTable(BuildContext context, List<ItemModel> items) {
    final headerColor = template == InvoiceTemplate.classic
        ? _classicNavy
        : template == InvoiceTemplate.elegant
            ? _elegantDark
            : accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: template == InvoiceTemplate.geometric
                ? const Color(0xFFE7E9ED)
                : (template == InvoiceTemplate.minimal ||
                        template == InvoiceTemplate.boutique)
                    ? Colors.transparent
                    : headerColor,
            border: template == InvoiceTemplate.minimal
                ? Border(
                    top: BorderSide(color: accentColor, width: 2),
                    bottom: const BorderSide(color: _borderGrey, width: 0.8),
                  )
                : (template == InvoiceTemplate.boutique ||
                        template == InvoiceTemplate.geometric)
                    ? const Border(
                        top: BorderSide(color: _borderGrey, width: 0.8),
                        bottom: BorderSide(color: _borderGrey, width: 0.8),
                      )
                    : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  context.tr('pdf_description'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: (template == InvoiceTemplate.minimal ||
                            template == InvoiceTemplate.boutique ||
                            template == InvoiceTemplate.geometric)
                        ? _textMid
                        : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  context.tr('pdf_qty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: (template == InvoiceTemplate.minimal ||
                            template == InvoiceTemplate.boutique ||
                            template == InvoiceTemplate.geometric)
                        ? _textMid
                        : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  context.tr('pdf_unit_price'),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: (template == InvoiceTemplate.minimal ||
                            template == InvoiceTemplate.boutique ||
                            template == InvoiceTemplate.geometric)
                        ? _textMid
                        : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(
                width: 66,
                child: Text(
                  context.tr('pdf_amount'),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: (template == InvoiceTemplate.minimal ||
                            template == InvoiceTemplate.boutique ||
                            template == InvoiceTemplate.geometric)
                        ? _textMid
                        : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final lineTotal = (item.price ?? 0) * (item.qty ?? 1);
          return Container(
            color: idx.isOdd ? _rowAlt : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      if ((item.note ?? '').isNotEmpty)
                        Text(item.note!,
                            style: const TextStyle(
                                fontSize: 9, color: _textMuted)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${item.qty ?? 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, color: _textMid),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '$currencySymbol${(item.price ?? 0).toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 11, color: _textMid),
                  ),
                ),
                SizedBox(
                  width: 66,
                  child: Text(
                    '$currencySymbol${lineTotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        Container(height: 0.8, color: _borderGrey),
      ],
    );
  }

  // ── Totals ─────────────────────────────────────────────────────────────
  Widget _buildTotals(BuildContext context, double subtotal, double discount,
      double received) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdj = hasDiscount || hasReceived;
    final finalAmt = hasAdj ? balanceDue : subtotal;
    final finalLabel = hasAdj
        ? context.tr('pdf_balance_due')
        : context.tr('pdf_total_due');

    if (template == InvoiceTemplate.classic ||
        template == InvoiceTemplate.wave) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 220,
          child: Column(
            children: [
              if (hasDiscount || hasReceived) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: _rowAlt,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Column(
                    children: [
                      _totRow(context.tr('pdf_subtotal'),
                          '$currencySymbol${subtotal.toStringAsFixed(2)}'),
                      if (hasDiscount) ...[
                        const SizedBox(height: 6),
                        _totRow(context.tr('pdf_discount'),
                            '-$currencySymbol${discount.toStringAsFixed(2)}',
                            valueColor: kDangerColor),
                      ],
                      if (hasReceived) ...[
                        const SizedBox(height: 6),
                        _totRow(context.tr('pdf_received'),
                            '($currencySymbol${received.toStringAsFixed(2)})',
                            valueColor: const Color(0xFF059669)),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                _totRow(context.tr('pdf_subtotal'),
                    '$currencySymbol${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
              ],
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: template == InvoiceTemplate.classic
                      ? _classicNavy
                      : accentColor,
                  borderRadius: BorderRadius.only(
                    topLeft:
                        hasAdj ? Radius.zero : const Radius.circular(10),
                    topRight:
                        hasAdj ? Radius.zero : const Radius.circular(10),
                    bottomLeft: const Radius.circular(10),
                    bottomRight: const Radius.circular(10),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      finalLabel.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$currencySymbol${finalAmt.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (template == InvoiceTemplate.elegant) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 210,
          child: Column(
            children: [
              _totRow(context.tr('pdf_subtotal'),
                  '$currencySymbol${subtotal.toStringAsFixed(2)}'),
              if (hasDiscount) ...[
                const SizedBox(height: 6),
                _totRow(context.tr('pdf_discount'),
                    '-$currencySymbol${discount.toStringAsFixed(2)}',
                    valueColor: kDangerColor),
              ],
              if (hasReceived) ...[
                const SizedBox(height: 6),
                _totRow(context.tr('pdf_received'),
                    '($currencySymbol${received.toStringAsFixed(2)})',
                    valueColor: const Color(0xFF059669)),
              ],
              const SizedBox(height: 10),
              Divider(color: accentColor, thickness: 1, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    finalLabel.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$currencySymbol${finalAmt.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Boutique: plain subtotal rows + full-width dark total box
    if (template == InvoiceTemplate.boutique) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 220,
          child: Column(
            children: [
              _totRow(context.tr('pdf_subtotal'),
                  '$currencySymbol${subtotal.toStringAsFixed(2)}'),
              if (hasDiscount) ...[
                const SizedBox(height: 6),
                _totRow(context.tr('pdf_discount'),
                    '-$currencySymbol${discount.toStringAsFixed(2)}',
                    valueColor: kDangerColor),
              ],
              if (hasReceived) ...[
                const SizedBox(height: 6),
                _totRow(context.tr('pdf_received'),
                    '($currencySymbol${received.toStringAsFixed(2)})',
                    valueColor: const Color(0xFF059669)),
              ],
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: _classicNavy),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      finalLabel.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$currencySymbol${finalAmt.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Geometric: clean rows + bold plain total
    if (template == InvoiceTemplate.geometric) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 220,
          child: Column(
            children: [
              if (hasDiscount) ...[
                _totRow(context.tr('pdf_subtotal'),
                    '$currencySymbol${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _totRow(context.tr('pdf_discount'),
                    '-$currencySymbol${discount.toStringAsFixed(2)}',
                    valueColor: kDangerColor),
              ],
              if (hasReceived) ...[
                const SizedBox(height: 6),
                _totRow(context.tr('pdf_received'),
                    '($currencySymbol${received.toStringAsFixed(2)})',
                    valueColor: const Color(0xFF059669)),
              ],
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.8, color: _borderGrey),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    finalLabel.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    '$currencySymbol${finalAmt.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Minimal
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            _totRow(context.tr('pdf_subtotal'),
                '$currencySymbol${subtotal.toStringAsFixed(2)}'),
            if (hasDiscount) ...[
              const SizedBox(height: 6),
              _totRow(context.tr('pdf_discount'),
                  '-$currencySymbol${discount.toStringAsFixed(2)}',
                  valueColor: kDangerColor),
            ],
            if (hasReceived) ...[
              const SizedBox(height: 6),
              _totRow(context.tr('pdf_received'),
                  '($currencySymbol${received.toStringAsFixed(2)})',
                  valueColor: const Color(0xFF059669)),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.8, color: _borderGrey),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  finalLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                Text(
                  '$currencySymbol${finalAmt.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10, color: _textMid)),
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _textDark,
            )),
      ],
    );
  }

  // ── Notes ──────────────────────────────────────────────────────────────
  Widget _buildNotes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context.tr('pdf_notes')),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _rowAlt,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _borderGrey, width: 0.5),
          ),
          child: Text(
            invoice.notes!,
            style: const TextStyle(
                fontSize: 10, color: _textMid, height: 1.5),
          ),
        ),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    final hasTerms = invoice.termsConditions?.isNotEmpty ?? false;

    final signatureWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          context.tr('pdf_signature'),
          style: const TextStyle(fontSize: 9, color: _textMuted),
        ),
        const SizedBox(height: 28),
        Container(
          width: 120,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _borderGrey, width: 0.8),
            ),
          ),
        ),
      ],
    );

    if (!hasTerms) {
      return Align(alignment: Alignment.centerRight, child: signatureWidget);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context.tr('pdf_terms')),
              const SizedBox(height: 6),
              Text(
                invoice.termsConditions!,
                style: const TextStyle(
                    fontSize: 9, color: _textMid, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        signatureWidget,
      ],
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────
  String _statusText(BuildContext context) {
    if (invoice.invoiceStatus == 'Paid') return context.tr('paid');
    return context.tr('unpaid');
  }

  String _docTypeLabel(BuildContext context) {
    final t = invoice.documentType ?? 'Invoice';
    if (t == 'Quote') return context.tr('pdf_quote');
    if (t == 'Estimate') return context.tr('pdf_estimate');
    return context.tr('pdf_invoice');
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: accentColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _logoWidget(double size,
      {bool rounded = false,
      bool whiteBg = false,
      Color? borderColor}) {
    final logoPath = business?.businessLogo;
    if (logoPath == null || logoPath.isEmpty) return const SizedBox.shrink();
    try {
      final file = File(logoPath);
      if (file.existsSync()) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: whiteBg ? Colors.white : null,
            borderRadius:
                rounded ? BorderRadius.circular(10) : BorderRadius.zero,
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(file,
              width: size, height: size, fit: BoxFit.cover),
        );
      }
    } catch (_) {}
    return const SizedBox.shrink();
  }
}

// ── Wave header painter ────────────────────────────────────────────────────────
class _WaveHeaderPainter extends CustomPainter {
  final Color color;
  const _WaveHeaderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Darker accent fills the full rect as a depth base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Color.lerp(color, Colors.black, 0.20)!,
    );

    // Main accent layer with smooth arch wave at the bottom
    // Both edges start at h-54, curve down to h-8 in the centre
    final wavePath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - 54)
      ..cubicTo(w * 0.65, h - 6, w * 0.35, h - 6, 0, h - 54)
      ..close();
    canvas.drawPath(wavePath, Paint()..color = color);

    // Subtle diagonal highlight for visual depth
    final hlPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.52, 0)
      ..cubicTo(w * 0.32, h * 0.32, w * 0.14, h * 0.52, 0, h * 0.44)
      ..close();
    canvas.drawPath(
      hlPath,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
  }

  @override
  bool shouldRepaint(_WaveHeaderPainter old) => old.color != color;
}

// ── Geometric corner triangles painter ────────────────────────────────────────
class _GeometricBgPainter extends CustomPainter {
  final Color accent;
  final Color secondary;
  _GeometricBgPainter(this.accent, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pink = Color(0xFFEDB8B8);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);

    const r1w = 92.0, r1h = 66.0;
    const r2 = 50.0;

    // Top-right: large accent rect (behind)
    canvas.drawRect(Rect.fromLTWH(w - r1w, 0, r1w, r1h), Paint()..color = accent);
    // Top-right: small pink rect (front, at very corner)
    canvas.drawRect(Rect.fromLTWH(w - r2, 0, r2, r2), Paint()..color = pink);

    // Bottom-left: large accent rect (behind)
    canvas.drawRect(Rect.fromLTWH(0, h - r1h, r1w, r1h), Paint()..color = accent);
    // Bottom-left: small pink rect (front, at very corner)
    canvas.drawRect(Rect.fromLTWH(0, h - r2, r2, r2), Paint()..color = pink);
  }

  @override
  bool shouldRepaint(_GeometricBgPainter old) =>
      old.accent != accent || old.secondary != secondary;
}
