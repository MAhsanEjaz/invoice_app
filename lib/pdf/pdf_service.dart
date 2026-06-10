import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

// ─── Font Cache ───────────────────────────────────────────────────────────────

class _PdfFonts {
  static pw.Font? _devanagari;
  static pw.Font? _arabic;

  static Future<pw.Font?> devanagari() async {
    if (_devanagari != null) return _devanagari;
    try {
      final data =
          await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      _devanagari = pw.Font.ttf(data);
      return _devanagari;
    } catch (_) {
      return null;
    }
  }

  static Future<pw.Font?> arabic() async {
    if (_arabic != null) return _arabic;
    try {
      final data =
          await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      _arabic = pw.Font.ttf(data);
      return _arabic;
    } catch (_) {
      return null;
    }
  }
}

// ─── Shared palette constants ─────────────────────────────────────────────────
const _classicNavy = PdfColor(0.059, 0.090, 0.149);   // #0F1726
const _elegantDark = PdfColor(0.067, 0.094, 0.118);   // #111826
const _rowAlt      = PdfColor(0.976, 0.980, 0.992);   // near-white blue tint
const _borderGrey  = PdfColor(0.882, 0.894, 0.914);
const _textDark    = PdfColor(0.122, 0.153, 0.216);
const _textMid     = PdfColor(0.424, 0.451, 0.522);
const _textMuted   = PdfColor(0.62,  0.643, 0.710);

// ─── PDF Generator ────────────────────────────────────────────────────────────

class PdfService {
  PdfColor _toPdf(Color color) => PdfColor(
        color.r.toDouble(),
        color.g.toDouble(),
        color.b.toDouble(),
      );

  PdfColor _darken(PdfColor c, double f) => PdfColor(
        (c.red * (1 - f)).clamp(0.0, 1.0),
        (c.green * (1 - f)).clamp(0.0, 1.0),
        (c.blue * (1 - f)).clamp(0.0, 1.0),
      );

  PdfColor _lighten(PdfColor c, double f) => PdfColor(
        (c.red + (1 - c.red) * f).clamp(0.0, 1.0),
        (c.green + (1 - c.green) * f).clamp(0.0, 1.0),
        (c.blue + (1 - c.blue) * f).clamp(0.0, 1.0),
      );

  String _docTypeTitle(String? docType, _PdfLabels l) {
    if (docType == 'Quote') return l.t('pdf_quote');
    if (docType == 'Estimate') return l.t('pdf_estimate');
    return l.t('pdf_invoice');
  }

  String _docTypeNo(String? docType, _PdfLabels l) {
    if (docType == 'Quote') return l.t('quote_no');
    if (docType == 'Estimate') return l.t('estimate_no');
    return l.t('pdf_invoice_no');
  }

  Future<Uint8List> invoicePdfGenerate(
    InvoiceModel invoice,
    TemplatesColorsProvider? provider, {
    BusinessModel? business,
    String currencySymbol = '\$',
    String locale = 'en',
  }) async {
    final pdf = pw.Document();
    final accentColor =
        provider != null ? _toPdf(provider.color) : PdfColor(0.051, 0.451, 0.467);
    final template = provider?.template ?? InvoiceTemplate.classic;

    final items = invoice.items ?? [];
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + ((item.price?.toDouble() ?? 0) * (item.qty ?? 1)),
    );

    pw.MemoryImage? logoImage;
    final logoPath = business?.businessLogo;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final file = File(logoPath);
        if (await file.exists()) {
          logoImage = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {}
    }

    pw.Font? customFont;
    if (locale == 'hi') {
      customFont = await _PdfFonts.devanagari();
    } else if (locale == 'ur') {
      customFont = await _PdfFonts.arabic();
    }

    final l = _PdfLabels(locale);

    switch (template) {
      case InvoiceTemplate.classic:
        pdf.addPage(_classicPage(invoice, business, accentColor, logoImage,
            items, subtotal, currencySymbol, l, customFont));
      case InvoiceTemplate.modern:
        pdf.addPage(_modernPage(invoice, business, accentColor, logoImage,
            items, subtotal, currencySymbol, l, customFont));
      case InvoiceTemplate.elegant:
        pdf.addPage(_elegantPage(invoice, business, accentColor, logoImage,
            items, subtotal, currencySymbol, l, customFont));
      case InvoiceTemplate.minimal:
        pdf.addPage(_minimalPage(invoice, business, accentColor, logoImage,
            items, subtotal, currencySymbol, l, customFont));
      case InvoiceTemplate.wave:
        pdf.addPage(_wavePage(invoice, business, accentColor, logoImage,
            items, subtotal, currencySymbol, l, customFont));
    }

    return pdf.save();
  }

  pw.PageTheme _pageTheme(_PdfLabels l) => pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        textDirection: l.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        buildBackground: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: PdfColors.white),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 1 – CLASSIC  (dark navy header · professional · corporate)
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _classicPage(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, List items, double subtotal,
    String sym, _PdfLabels l, pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: _pageTheme(l),
      build: (ctx) => [
        _classicHeader(invoice, business, accent, logo, l, font),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 28),
              _classicTable(items, accent, sym, l, font),
              pw.SizedBox(height: 20),
              _classicTotals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, accent, l, font),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                _notes(invoice.notes!, l, font),
              ],
              pw.SizedBox(height: 40),
              _footer(invoice.termsConditions, l, font),
            ],
          ),
        ),
      ],
    ) as pw.Page;
  }

  pw.Widget _classicHeader(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, _PdfLabels l, pw.Font? font,
  ) {
    final businessName =
        invoice.businessName ?? business?.businessName ?? l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    final navyLight = PdfColor(0.141, 0.192, 0.294); // lighter navy for badge bg

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          decoration: const pw.BoxDecoration(color: _classicNavy),
          padding: const pw.EdgeInsets.fromLTRB(40, 38, 40, 34),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left – logo + company
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null) ...[
                    pw.Container(
                      width: 64,
                      height: 64,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 12,
                        verticalRadius: 12,
                        child: pw.Image(logo,
                            width: 64, height: 64, fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.SizedBox(width: 18),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                            font: bold, fontSize: 22, color: PdfColors.white),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: navyLight,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        child: pw.Text(
                          '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                          style: pw.TextStyle(
                              font: bold,
                              fontSize: 9,
                              color: PdfColors.white,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Right – INVOICE title + meta
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _docTypeTitle(invoice.documentType, l).toUpperCase(),
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 36,
                        color: PdfColors.white,
                        letterSpacing: l.isRtl ? 0 : 4),
                  ),
                  pw.SizedBox(height: 14),
                  if (invoice.date?.isNotEmpty ?? false)
                    _classicMetaLine(
                        l.t('pdf_date'), invoice.date!, regular),
                  if (invoice.dueDate?.isNotEmpty ?? false)
                    _classicMetaLine(
                        l.t('pdf_due'), invoice.dueDate!, regular),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Text(
                      _localizedStatus(invoice.invoiceStatus, l).toUpperCase(),
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 9,
                          color: PdfColors.white,
                          letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(height: 4, color: accent),
      ],
    );
  }

  pw.Widget _classicMetaLine(String label, String value, pw.Font regular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label  ',
              style: pw.TextStyle(
                  font: regular, fontSize: 10, color: _textMuted)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: regular, fontSize: 10, color: PdfColors.white)),
        ],
      ),
    );
  }

  pw.Widget _classicTable(
      List items, PdfColor accent, String sym, _PdfLabels l, pw.Font? font) {
    final bold = font ?? pw.Font.helveticaBold();
    final regular = font ?? pw.Font.helvetica();
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGrey, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _classicNavy),
          children: [
            _th(l.t('pdf_description'), font: font),
            _th(l.t('pdf_qty'), align: pw.Alignment.center, font: font),
            _th(l.t('pdf_unit_price'),
                align: pw.Alignment.centerRight, font: font),
            _th(l.t('pdf_amount'),
                align: pw.Alignment.centerRight, font: font),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isOdd ? _rowAlt : PdfColors.white),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.itemName ?? '',
                        style: pw.TextStyle(
                            font: bold, fontSize: 10, color: _textDark)),
                    if ((item.note ?? '').isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(item.note!,
                          style: pw.TextStyle(
                              font: regular,
                              fontSize: 8,
                              color: _textMuted)),
                    ],
                  ],
                ),
              ),
              _td('${item.qty ?? 1}',
                  align: pw.Alignment.center, font: font),
              _td('$sym${unitPrice.toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, font: font),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, bold: true, font: font),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _classicTotals(double subtotal, double discount, double received,
      String sym, PdfColor accent, _PdfLabels l, pw.Font? font) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdj = hasDiscount || hasReceived;
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 260,
        child: pw.Column(
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderGrey, width: 0.5),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: pw.Column(
                children: [
                  _totRow(l.t('pdf_subtotal'),
                      '$sym${subtotal.toStringAsFixed(2)}', regular, bold),
                  if (hasDiscount) ...[
                    pw.SizedBox(height: 6),
                    _totRow(l.t('pdf_discount'),
                        '-$sym${discount.toStringAsFixed(2)}', regular, bold,
                        valueColor: PdfColors.orange700),
                  ],
                  if (hasReceived) ...[
                    pw.SizedBox(height: 6),
                    _totRow(l.t('pdf_received'),
                        '($sym${received.toStringAsFixed(2)})', regular, bold,
                        valueColor: PdfColors.green700),
                  ],
                ],
              ),
            ),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: _classicNavy,
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(8),
                  bottomRight: pw.Radius.circular(8),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    (hasAdj
                            ? l.t('pdf_balance_due')
                            : l.t('pdf_total_due'))
                        .toUpperCase(),
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 0.5),
                  ),
                  pw.Text(
                    '$sym${(hasAdj ? balanceDue : subtotal).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        font: bold, fontSize: 16, color: PdfColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 2 – MODERN  (split white/accent · bold · tech-forward)
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _modernPage(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, List items, double subtotal,
    String sym, _PdfLabels l, pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: _pageTheme(l),
      build: (ctx) => [
        _modernHeader(invoice, business, accent, logo, l, font),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 28),
              _modernTable(items, accent, sym, l, font),
              pw.SizedBox(height: 20),
              _modernTotals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, accent, l, font),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                _notes(invoice.notes!, l, font),
              ],
              pw.SizedBox(height: 40),
              _footer(invoice.termsConditions, l, font),
            ],
          ),
        ),
      ],
    ) as pw.Page;
  }

  pw.Widget _modernHeader(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, _PdfLabels l, pw.Font? font,
  ) {
    final businessName =
        invoice.businessName ?? business?.businessName ?? l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    final accentLight = _lighten(accent, 0.88);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
          // Left white panel
          pw.Expanded(
            flex: 58,
            child: pw.Container(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              padding: const pw.EdgeInsets.fromLTRB(40, 36, 28, 36),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (logo != null) ...[
                    pw.ClipRRect(
                      horizontalRadius: 10,
                      verticalRadius: 10,
                      child: pw.Image(logo,
                          width: 60, height: 60, fit: pw.BoxFit.cover),
                    ),
                    pw.SizedBox(height: 14),
                  ],
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(
                        font: bold, fontSize: 22, color: _textDark),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: 48,
                    height: 4,
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: accentLight,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                      style: pw.TextStyle(
                          font: bold, fontSize: 9, color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right accent panel
          pw.Expanded(
            flex: 42,
            child: pw.Container(
              decoration: pw.BoxDecoration(color: accent),
              padding: const pw.EdgeInsets.fromLTRB(24, 36, 40, 36),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    _docTypeTitle(invoice.documentType, l).toUpperCase(),
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 26,
                        color: PdfColors.white,
                        letterSpacing: l.isRtl ? 0 : 3),
                  ),
                  pw.SizedBox(height: 16),
                  if (invoice.date?.isNotEmpty ?? false)
                    _modernInfoLine(l.t('pdf_date'), invoice.date!, regular),
                  if (invoice.dueDate?.isNotEmpty ?? false)
                    _modernInfoLine(l.t('pdf_due'), invoice.dueDate!, regular),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Text(
                      _localizedStatus(invoice.invoiceStatus, l).toUpperCase(),
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 9,
                          color: accent,
                          letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }

  pw.Widget _modernInfoLine(String label, String value, pw.Font regular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label  ',
              style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: const PdfColor(0.85, 0.87, 0.92))),
          pw.Text(value,
              style: pw.TextStyle(
                  font: regular, fontSize: 9, color: PdfColors.white)),
        ],
      ),
    );
  }

  pw.Widget _modernTable(
      List items, PdfColor accent, String sym, _PdfLabels l, pw.Font? font) {
    final bold = font ?? pw.Font.helveticaBold();
    final regular = font ?? pw.Font.helvetica();
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside:
            const pw.BorderSide(color: _borderGrey, width: 0.5),
        bottom: const pw.BorderSide(color: _borderGrey, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: accent, width: 2.5)),
          ),
          children: [
            _modernTh(l.t('pdf_description'), accent, font: font),
            _modernTh(l.t('pdf_qty'), accent,
                align: pw.Alignment.center, font: font),
            _modernTh(l.t('pdf_unit_price'), accent,
                align: pw.Alignment.centerRight, font: font),
            _modernTh(l.t('pdf_amount'), accent,
                align: pw.Alignment.centerRight, font: font),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.itemName ?? '',
                        style: pw.TextStyle(
                            font: bold, fontSize: 10, color: _textDark)),
                    if ((item.note ?? '').isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(item.note!,
                          style: pw.TextStyle(
                              font: regular,
                              fontSize: 8,
                              color: _textMuted)),
                    ],
                  ],
                ),
              ),
              _td('${item.qty ?? 1}',
                  align: pw.Alignment.center, font: font),
              _td('$sym${unitPrice.toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, font: font),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, bold: true, font: font),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _modernTh(String text, PdfColor accent,
      {pw.Alignment align = pw.Alignment.centerLeft, pw.Font? font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font ?? pw.Font.helveticaBold(),
              fontSize: 9,
              color: accent,
              letterSpacing: 0.6)),
    );
  }

  pw.Widget _modernTotals(
    double subtotal, double discount, double received,
    String sym, PdfColor accent, _PdfLabels l, pw.Font? font,
  ) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdj = hasDiscount || hasReceived;
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 260,
        child: pw.Column(
          children: [
            if (hasDiscount || hasReceived) ...[
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: pw.BoxDecoration(
                  color: _rowAlt,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  children: [
                    _totRow(l.t('pdf_subtotal'),
                        '$sym${subtotal.toStringAsFixed(2)}', regular, bold),
                    if (hasDiscount) ...[
                      pw.SizedBox(height: 6),
                      _totRow(l.t('pdf_discount'),
                          '-$sym${discount.toStringAsFixed(2)}', regular, bold,
                          valueColor: PdfColors.orange700),
                    ],
                    if (hasReceived) ...[
                      pw.SizedBox(height: 6),
                      _totRow(l.t('pdf_received'),
                          '($sym${received.toStringAsFixed(2)})', regular, bold,
                          valueColor: PdfColors.green700),
                    ],
                  ],
                ),
              ),
            ] else ...[
              _totRow(l.t('pdf_subtotal'),
                  '$sym${subtotal.toStringAsFixed(2)}', regular, bold),
              pw.SizedBox(height: 8),
            ],
            pw.Container(
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.only(
                  topLeft: hasAdj
                      ? pw.Radius.zero
                      : const pw.Radius.circular(8),
                  topRight: hasAdj
                      ? pw.Radius.zero
                      : const pw.Radius.circular(8),
                  bottomLeft: const pw.Radius.circular(8),
                  bottomRight: const pw.Radius.circular(8),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    hasAdj
                        ? l.t('pdf_balance_due').toUpperCase()
                        : l.t('pdf_total_due').toUpperCase(),
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 0.5),
                  ),
                  pw.Text(
                    '$sym${(hasAdj ? balanceDue : subtotal).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        font: bold, fontSize: 16, color: PdfColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 3 – ELEGANT  (deep dark · luxury · premium)
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _elegantPage(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, List items, double subtotal,
    String sym, _PdfLabels l, pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: _pageTheme(l),
      build: (ctx) => [
        _elegantHeader(invoice, business, accent, logo, l, font),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 28),
              _elegantTable(items, accent, sym, l, font),
              pw.SizedBox(height: 20),
              _elegantTotals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, accent, l, font),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                _notes(invoice.notes!, l, font),
              ],
              pw.SizedBox(height: 40),
              _footer(invoice.termsConditions, l, font),
            ],
          ),
        ),
      ],
    ) as pw.Page;
  }

  pw.Widget _elegantHeader(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, _PdfLabels l, pw.Font? font,
  ) {
    final businessName =
        invoice.businessName ?? business?.businessName ?? l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    const dividerColor = PdfColor(0.20, 0.24, 0.33);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          decoration: const pw.BoxDecoration(color: _elegantDark),
          padding: const pw.EdgeInsets.fromLTRB(40, 38, 40, 34),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Left – logo + company
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null) ...[
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: pw.BoxDecoration(
                        color: PdfColor(0.12, 0.16, 0.24),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(10)),
                        border: pw.Border.all(color: dividerColor, width: 1),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 10,
                        verticalRadius: 10,
                        child: pw.Image(logo,
                            width: 60, height: 60, fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.SizedBox(width: 18),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                            font: bold, fontSize: 22, color: PdfColors.white),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                        style: pw.TextStyle(
                            font: regular,
                            fontSize: 10,
                            color: const PdfColor(0.50, 0.55, 0.65)),
                      ),
                      if (invoice.date?.isNotEmpty ?? false) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          '${l.t('pdf_date')}: ${invoice.date!}',
                          style: pw.TextStyle(
                              font: regular,
                              fontSize: 10,
                              color: const PdfColor(0.50, 0.55, 0.65)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Right – INVOICE in accent
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _docTypeTitle(invoice.documentType, l).toUpperCase(),
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 34,
                        color: accent,
                        letterSpacing: l.isRtl ? 0 : 4),
                  ),
                  pw.SizedBox(height: 10),
                  if (invoice.dueDate?.isNotEmpty ?? false)
                    pw.Text(
                      '${l.t('pdf_due')}: ${invoice.dueDate!}',
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: const PdfColor(0.55, 0.60, 0.70)),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: accent, width: 1),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      _localizedStatus(invoice.invoiceStatus, l).toUpperCase(),
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 9,
                          color: accent,
                          letterSpacing: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(height: 4, color: accent),
      ],
    );
  }

  pw.Widget _elegantTable(
      List items, PdfColor accent, String sym, _PdfLabels l, pw.Font? font) {
    final bold = font ?? pw.Font.helveticaBold();
    final regular = font ?? pw.Font.helvetica();
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside:
            const pw.BorderSide(color: _borderGrey, width: 0.4),
        bottom: const pw.BorderSide(color: _borderGrey, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _elegantDark),
          children: [
            _th(l.t('pdf_description'), font: font),
            _th(l.t('pdf_qty'), align: pw.Alignment.center, font: font),
            _th(l.t('pdf_unit_price'),
                align: pw.Alignment.centerRight, font: font),
            _th(l.t('pdf_amount'),
                align: pw.Alignment.centerRight, font: font),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isOdd ? _rowAlt : PdfColors.white),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.itemName ?? '',
                        style: pw.TextStyle(
                            font: bold, fontSize: 10, color: _textDark)),
                    if ((item.note ?? '').isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(item.note!,
                          style: pw.TextStyle(
                              font: regular,
                              fontSize: 8,
                              color: _textMuted)),
                    ],
                  ],
                ),
              ),
              _td('${item.qty ?? 1}',
                  align: pw.Alignment.center, font: font),
              _td('$sym${unitPrice.toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, font: font),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, bold: true, font: font),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _elegantTotals(double subtotal, double discount, double received,
      String sym, PdfColor accent, _PdfLabels l, pw.Font? font) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdj = hasDiscount || hasReceived;
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 240,
        child: pw.Column(
          children: [
            _totRow(l.t('pdf_subtotal'),
                '$sym${subtotal.toStringAsFixed(2)}', regular, bold),
            if (hasDiscount) ...[
              pw.SizedBox(height: 6),
              _totRow(l.t('pdf_discount'),
                  '-$sym${discount.toStringAsFixed(2)}', regular, bold,
                  valueColor: PdfColors.orange700),
            ],
            if (hasReceived) ...[
              pw.SizedBox(height: 6),
              _totRow(l.t('pdf_received'),
                  '($sym${received.toStringAsFixed(2)})', regular, bold,
                  valueColor: PdfColors.green700),
            ],
            pw.SizedBox(height: 8),
            pw.Container(
              margin:
                  const pw.EdgeInsets.only(bottom: 8),
              child:
                  pw.Divider(color: accent, thickness: 1),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  hasAdj
                      ? l.t('pdf_balance_due').toUpperCase()
                      : l.t('pdf_total_due').toUpperCase(),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 11,
                      color: _textDark,
                      letterSpacing: 0.5),
                ),
                pw.Text(
                  '$sym${(hasAdj ? balanceDue : subtotal).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      font: bold, fontSize: 18, color: accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 4 – MINIMAL  (clean · whitespace · typography-first)
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _minimalPage(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, List items, double subtotal,
    String sym, _PdfLabels l, pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: _pageTheme(l),
      build: (ctx) => [
        pw.Container(height: 5, color: accent),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(48, 36, 48, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _minimalHeader(invoice, business, accent, logo, l, font),
              pw.SizedBox(height: 36),
              pw.Divider(color: _borderGrey, thickness: 0.8),
              pw.SizedBox(height: 28),
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 32),
              _minimalTable(items, accent, sym, l, font),
              pw.SizedBox(height: 24),
              _minimalTotals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, accent, l, font),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 24),
                _notes(invoice.notes!, l, font),
              ],
              pw.SizedBox(height: 48),
              _footer(invoice.termsConditions, l, font),
            ],
          ),
        ),
      ],
    ) as pw.Page;
  }

  pw.Widget _minimalHeader(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, _PdfLabels l, pw.Font? font,
  ) {
    final businessName =
        invoice.businessName ?? business?.businessName ?? l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    final accentLight = _lighten(accent, 0.88);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left – logo + company name
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.ClipRRect(
                horizontalRadius: 10,
                verticalRadius: 10,
                child: pw.Image(logo,
                    width: 56, height: 56, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(width: 16),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                      font: bold, fontSize: 26, color: _textDark),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 40,
                  height: 3,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: accentLight,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                    style: pw.TextStyle(
                        font: bold, fontSize: 9, color: accent),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Right – date info + status
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (invoice.date?.isNotEmpty ?? false)
              pw.Text(
                invoice.date!,
                style: pw.TextStyle(
                    font: regular, fontSize: 11, color: _textMuted),
              ),
            if (invoice.dueDate?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 5),
              pw.Text(
                '${l.t('pdf_due')} ${invoice.dueDate!}',
                style: pw.TextStyle(
                    font: bold, fontSize: 11, color: _textDark),
              ),
            ],
            pw.SizedBox(height: 10),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: accent, width: 1),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                _localizedStatus(invoice.invoiceStatus, l).toUpperCase(),
                style: pw.TextStyle(
                    font: bold,
                    fontSize: 9,
                    color: accent,
                    letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _minimalTable(
      List items, PdfColor accent, String sym, _PdfLabels l, pw.Font? font) {
    final bold = font ?? pw.Font.helveticaBold();
    final regular = font ?? pw.Font.helvetica();
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: accent, width: 2),
        bottom: const pw.BorderSide(color: _borderGrey, width: 0.5),
        horizontalInside:
            const pw.BorderSide(color: _borderGrey, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          children: [
            _minimalTh(l.t('pdf_description'), font: font),
            _minimalTh(l.t('pdf_qty'),
                align: pw.Alignment.center, font: font),
            _minimalTh(l.t('pdf_unit_price'),
                align: pw.Alignment.centerRight, font: font),
            _minimalTh(l.t('pdf_amount'),
                align: pw.Alignment.centerRight, font: font),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isOdd ? _rowAlt : PdfColors.white),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.itemName ?? '',
                        style: pw.TextStyle(
                            font: bold, fontSize: 10, color: _textDark)),
                    if ((item.note ?? '').isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(item.note!,
                          style: pw.TextStyle(
                              font: regular,
                              fontSize: 8,
                              color: _textMuted)),
                    ],
                  ],
                ),
              ),
              _td('${item.qty ?? 1}',
                  align: pw.Alignment.center, font: font),
              _td('$sym${unitPrice.toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, font: font),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, bold: true, font: font),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _minimalTh(String text,
      {pw.Alignment align = pw.Alignment.centerLeft, pw.Font? font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font ?? pw.Font.helveticaBold(),
              fontSize: 8,
              color: _textMid,
              letterSpacing: 0.8)),
    );
  }

  pw.Widget _minimalTotals(double subtotal, double discount, double received,
      String sym, PdfColor accent, _PdfLabels l, pw.Font? font) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdj = hasDiscount || hasReceived;
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 230,
        child: pw.Column(
          children: [
            _totRow(l.t('pdf_subtotal'),
                '$sym${subtotal.toStringAsFixed(2)}', regular, bold),
            if (hasDiscount) ...[
              pw.SizedBox(height: 6),
              _totRow(l.t('pdf_discount'),
                  '-$sym${discount.toStringAsFixed(2)}', regular, bold,
                  valueColor: PdfColors.orange700),
            ],
            if (hasReceived) ...[
              pw.SizedBox(height: 6),
              _totRow(l.t('pdf_received'),
                  '($sym${received.toStringAsFixed(2)})', regular, bold,
                  valueColor: PdfColors.green700),
            ],
            pw.SizedBox(height: 10),
            pw.Divider(color: _borderGrey, thickness: 0.8),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  hasAdj ? l.t('pdf_balance_due') : l.t('pdf_total_due'),
                  style:
                      pw.TextStyle(font: bold, fontSize: 13, color: _textDark),
                ),
                pw.Text(
                  '$sym${(hasAdj ? balanceDue : subtotal).toStringAsFixed(2)}',
                  style: pw.TextStyle(font: bold, fontSize: 16, color: accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 5 – WAVE  (curved header · vibrant · creative)
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _wavePage(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, List items, double subtotal,
    String sym, _PdfLabels l, pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: _pageTheme(l),
      build: (ctx) => [
        _waveHeader(invoice, business, accent, logo, l, font),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 20, 40, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _waveInfoCards(invoice, accent, l, font),
              pw.SizedBox(height: 28),
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 28),
              _waveTable(items, accent, sym, l, font),
              pw.SizedBox(height: 20),
              _waveTotals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, accent, l, font),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                _notes(invoice.notes!, l, font),
              ],
              pw.SizedBox(height: 40),
              _footer(invoice.termsConditions, l, font),
            ],
          ),
        ),
      ],
    ) as pw.Page;
  }

  pw.Widget _waveHeader(
    InvoiceModel invoice, BusinessModel? business, PdfColor accent,
    pw.MemoryImage? logo, _PdfLabels l, pw.Font? font,
  ) {
    const waveH = 58.0;
    const contentH = 140.0;
    const totalH = contentH + waveH;

    final businessName =
        invoice.businessName ?? business?.businessName ?? l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    final accentDark = _darken(accent, 0.20);
    final accentLight = _lighten(accent, 0.80);

    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        final w = size.x;
        final h = size.y;

        // Dark base fills the full rectangle
        canvas
          ..setFillColor(accentDark)
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..closePath()
          ..fillPath();

        // Main accent layer with smooth arch wave at the bottom
        // Both sides start at h-waveH, arch curves DOWN to h-8 in the centre
        canvas
          ..setFillColor(accent)
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w, h - waveH)
          ..curveTo(w * 0.65, h - 8, w * 0.35, h - 8, 0, h - waveH)
          ..closePath()
          ..fillPath();
      },
      child: pw.Container(
        width: double.infinity,
        height: totalH,
        padding: pw.EdgeInsets.fromLTRB(40, 36, 40, waveH + 14),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Left: logo + company name + number pill
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null) ...[
                  pw.Container(
                    width: 54,
                    height: 54,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(12)),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 12,
                      verticalRadius: 12,
                      child: pw.Image(logo,
                          width: 54, height: 54, fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                          font: bold, fontSize: 20, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: accentLight,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                        style: pw.TextStyle(
                            font: regular,
                            fontSize: 10,
                            color: accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Right: document type title
            pw.Text(
              _docTypeTitle(invoice.documentType, l).toUpperCase(),
              style: pw.TextStyle(
                  font: bold,
                  fontSize: 28,
                  color: PdfColors.white,
                  letterSpacing: l.isRtl ? 0 : 3),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _waveInfoCards(
      InvoiceModel invoice, PdfColor accent, _PdfLabels l, pw.Font? font) {
    final bold = font ?? pw.Font.helveticaBold();
    final isInvoice =
        invoice.documentType == null || invoice.documentType == 'Invoice';
    final accentLight = _lighten(accent, 0.90);

    pw.Widget card(String label, String value, {bool isStatus = false}) {
      final isPaid = invoice.invoiceStatus == 'Paid';
      final statusColor = isPaid
          ? const PdfColor(0.09, 0.64, 0.29)
          : const PdfColor(0.85, 0.47, 0.08);

      return pw.Expanded(
        child: pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: _borderGrey, width: 0.5),
            boxShadow: const [
              pw.BoxShadow(
                color: PdfColor(0, 0, 0, 0.06),
                blurRadius: 6,
                offset: PdfPoint(0, 2),
              ),
            ],
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: accentLight,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  label.toUpperCase(),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 7,
                      color: accent,
                      letterSpacing: 0.6),
                ),
              ),
              pw.SizedBox(height: 6),
              if (isStatus && isInvoice)
                pw.Row(
                  children: [
                    pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(
                          color: statusColor,
                          shape: pw.BoxShape.circle),
                    ),
                    pw.SizedBox(width: 5),
                    pw.Text(value,
                        style: pw.TextStyle(
                            font: bold,
                            fontSize: 12,
                            color: statusColor)),
                  ],
                )
              else
                pw.Text(value,
                    style: pw.TextStyle(
                        font: bold, fontSize: 12, color: _textDark)),
            ],
          ),
        ),
      );
    }

    final statusLabel = isInvoice
        ? _localizedStatus(invoice.invoiceStatus, l)
        : _docTypeTitle(invoice.documentType, l);

    return pw.Row(
      children: [
        card(l.t('pdf_date'),
            invoice.date?.isNotEmpty == true ? invoice.date! : '-'),
        pw.SizedBox(width: 10),
        card(l.t('pdf_due'),
            (invoice.dueDate?.isNotEmpty ?? false) ? invoice.dueDate! : '-'),
        pw.SizedBox(width: 10),
        card(l.t('pdf_status'), statusLabel, isStatus: true),
      ],
    );
  }

  pw.Widget _waveTable(
      List items, PdfColor accent, String sym, _PdfLabels l, pw.Font? font) {
    final bold = font ?? pw.Font.helveticaBold();
    final regular = font ?? pw.Font.helvetica();
    final accentLight = _lighten(accent, 0.90);

    return pw.Table(
      border: pw.TableBorder(
        bottom: const pw.BorderSide(color: _borderGrey, width: 0.5),
        horizontalInside:
            const pw.BorderSide(color: _borderGrey, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: accentLight,
            border: pw.Border(
                bottom: pw.BorderSide(color: accent, width: 2)),
          ),
          children: [
            _waveTh(l.t('pdf_description'), accent, font: font),
            _waveTh(l.t('pdf_qty'), accent,
                align: pw.Alignment.center, font: font),
            _waveTh(l.t('pdf_unit_price'), accent,
                align: pw.Alignment.centerRight, font: font),
            _waveTh(l.t('pdf_amount'), accent,
                align: pw.Alignment.centerRight, font: font),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: i.isOdd ? _rowAlt : PdfColors.white),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.itemName ?? '',
                        style: pw.TextStyle(
                            font: bold, fontSize: 10, color: _textDark)),
                    if ((item.note ?? '').isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(item.note!,
                          style: pw.TextStyle(
                              font: regular,
                              fontSize: 8,
                              color: _textMuted)),
                    ],
                  ],
                ),
              ),
              _td('${item.qty ?? 1}',
                  align: pw.Alignment.center, font: font),
              _td('$sym${unitPrice.toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, font: font),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}',
                  align: pw.Alignment.centerRight, bold: true, font: font),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _waveTh(String text, PdfColor accent,
      {pw.Alignment align = pw.Alignment.centerLeft, pw.Font? font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font ?? pw.Font.helveticaBold(),
              fontSize: 9,
              color: accent,
              letterSpacing: 0.6)),
    );
  }

  pw.Widget _waveTotals(
    double subtotal, double discount, double received,
    String sym, PdfColor accent, _PdfLabels l, pw.Font? font,
  ) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdj = hasDiscount || hasReceived;
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    final accentLight = _lighten(accent, 0.92);

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 270,
        child: pw.Column(
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
              decoration: pw.BoxDecoration(
                color: accentLight,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(12),
                  topRight: pw.Radius.circular(12),
                ),
              ),
              child: pw.Column(
                children: [
                  _totRow(l.t('pdf_subtotal'),
                      '$sym${subtotal.toStringAsFixed(2)}', regular, bold),
                  if (hasDiscount) ...[
                    pw.SizedBox(height: 6),
                    _totRow(l.t('pdf_discount'),
                        '-$sym${discount.toStringAsFixed(2)}', regular, bold,
                        valueColor: PdfColors.orange700),
                  ],
                  if (hasReceived) ...[
                    pw.SizedBox(height: 6),
                    _totRow(l.t('pdf_received'),
                        '($sym${received.toStringAsFixed(2)})', regular, bold,
                        valueColor: PdfColors.green700),
                  ],
                ],
              ),
            ),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(12),
                  bottomRight: pw.Radius.circular(12),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    hasAdj
                        ? l.t('pdf_balance_due').toUpperCase()
                        : l.t('pdf_total_due').toUpperCase(),
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 0.5),
                  ),
                  pw.Text(
                    '$sym${(hasAdj ? balanceDue : subtotal).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        font: bold, fontSize: 18, color: PdfColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Widget _fromToSection(
    InvoiceModel invoice, BusinessModel? business,
    _PdfLabels l, pw.Font? font,
  ) {
    final client = (invoice.clients?.isNotEmpty ?? false)
        ? invoice.clients!.first
        : null;
    final bank = invoice.bank;
    final businessName = invoice.businessName ??
        business?.businessName ??
        l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                l.t('pdf_from').toUpperCase(),
                style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    color: _textMuted,
                    letterSpacing: 1.5),
              ),
              pw.SizedBox(height: 8),
              pw.Text(businessName,
                  style: pw.TextStyle(
                      font: bold, fontSize: 13, color: _textDark)),
              if (bank != null) ...[
                pw.SizedBox(height: 5),
                if (bank.bankName?.isNotEmpty ?? false)
                  pw.Text(bank.bankName!,
                      style: pw.TextStyle(
                          font: regular, fontSize: 10, color: _textMid)),
                if (bank.title?.isNotEmpty ?? false)
                  pw.Text(bank.title!,
                      style: pw.TextStyle(
                          font: regular, fontSize: 10, color: _textMid)),
                if (bank.accountNumber?.isNotEmpty ?? false)
                  pw.Text(bank.accountNumber!,
                      style: pw.TextStyle(
                          font: bold, fontSize: 10, color: _textDark)),
              ],
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                l.t('pdf_invoice_to').toUpperCase(),
                style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    color: _textMuted,
                    letterSpacing: 1.5),
              ),
              pw.SizedBox(height: 8),
              if (client != null) ...[
                pw.Text(client.name ?? '',
                    style: pw.TextStyle(
                        font: bold, fontSize: 13, color: _textDark)),
                if (client.email?.isNotEmpty ?? false)
                  pw.Text(client.email!,
                      style: pw.TextStyle(
                          font: regular, fontSize: 10, color: _textMid)),
                if (client.phone?.isNotEmpty ?? false)
                  pw.Text(client.phone!,
                      style: pw.TextStyle(
                          font: regular, fontSize: 10, color: _textMid)),
                if (client.address?.isNotEmpty ?? false)
                  pw.Text(client.address!,
                      style: pw.TextStyle(
                          font: regular, fontSize: 10, color: _textMid)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _th(String text,
      {pw.Alignment align = pw.Alignment.centerLeft, pw.Font? font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font ?? pw.Font.helveticaBold(),
              fontSize: 9,
              color: PdfColors.white,
              letterSpacing: 0.5)),
    );
  }

  pw.Widget _td(String text,
      {pw.Alignment align = pw.Alignment.centerLeft,
      bool bold = false,
      pw.Font? font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: bold
                  ? (font ?? pw.Font.helveticaBold())
                  : (font ?? pw.Font.helvetica()),
              fontSize: 10,
              color: _textDark)),
    );
  }

  pw.Widget _totRow(
    String label, String value, pw.Font regular, pw.Font bold, {
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style:
                pw.TextStyle(font: regular, fontSize: 10, color: _textMid)),
        pw.Text(value,
            style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                color: valueColor ?? _textDark)),
      ],
    );
  }

  pw.Widget _notes(String notes, _PdfLabels l, pw.Font? font) {
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l.t('pdf_notes').toUpperCase(),
          style: pw.TextStyle(
              font: bold,
              fontSize: 8,
              color: _textMuted,
              letterSpacing: 1.5),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _rowAlt,
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: _borderGrey, width: 0.5),
          ),
          child: pw.Text(notes,
              style: pw.TextStyle(
                  font: regular, fontSize: 10, color: _textMid)),
        ),
      ],
    );
  }

  pw.Widget _footer(String? termsConditions, _PdfLabels l, pw.Font? font) {
    final hasTerms = termsConditions?.isNotEmpty ?? false;
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();

    final signatureWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(l.t('pdf_signature'),
            style: pw.TextStyle(
                font: regular, fontSize: 9, color: _textMuted)),
        pw.SizedBox(height: 30),
        pw.Container(
          width: 130,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: _borderGrey, width: 0.8)),
          ),
        ),
      ],
    );

    if (!hasTerms) {
      return pw.Align(
          alignment: pw.Alignment.centerRight, child: signatureWidget);
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                l.t('pdf_terms').toUpperCase(),
                style: pw.TextStyle(
                    font: bold,
                    fontSize: 8,
                    letterSpacing: 1,
                    color: _textMuted),
              ),
              pw.SizedBox(height: 6),
              pw.Text(termsConditions!,
                  style: pw.TextStyle(
                      font: regular, fontSize: 9, color: _textMid)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        signatureWidget,
      ],
    );
  }

  String _localizedStatus(String? status, _PdfLabels l) {
    if (status == 'Paid') return l.t('paid');
    return l.t('unpaid');
  }
}

// ─── PDF Label Helper ─────────────────────────────────────────────────────────

class _PdfLabels {
  final String _lang;
  const _PdfLabels(this._lang);

  bool get isRtl => _lang == 'ur';

  String t(String key) => AppTranslations.tl(_lang, key);
}

// ─── PDF Preview Screen ───────────────────────────────────────────────────────

class PdfInvoiceScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  final TemplatesColorsProvider? provider;

  const PdfInvoiceScreen({super.key, this.invoice, this.provider});

  @override
  State<PdfInvoiceScreen> createState() => _PdfInvoiceScreenState();
}

class _PdfInvoiceScreenState extends State<PdfInvoiceScreen> {
  final _pdfService = PdfService();
  BusinessModel? _business;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bp = Provider.of<BusinessProvider>(context, listen: false);
      final invoiceBusinessId = widget.invoice?.businessId;
      if (invoiceBusinessId != null && bp.businesses.isNotEmpty) {
        _business = bp.businesses.firstWhere(
          (b) => b.id == invoiceBusinessId,
          orElse: () => bp.activeBusiness ?? bp.businesses.first,
        );
      } else {
        _business = await bp.getString();
      }
      if (mounted) setState(() {});
    });
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) =>
      _pdfService.invoicePdfGenerate(
        widget.invoice!,
        widget.provider,
        business: _business,
        currencySymbol: Provider.of<CurrencyProvider>(context, listen: false)
            .currency
            .pdfSymbol,
        locale: 'en',
      );

  Future<void> _openPdf({required bool persist}) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await _pdfService.invoicePdfGenerate(
        widget.invoice!,
        widget.provider,
        business: _business,
        currencySymbol: Provider.of<CurrencyProvider>(context, listen: false)
            .currency
            .pdfSymbol,
        locale: 'en',
      );
      final invoiceId = widget.invoice?.invoiceId ?? 'draft';
      if (persist) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Invoice_$invoiceId.pdf');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open(file.path);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/Invoice_$invoiceId.pdf');
        await file.writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _exportAsImage({required bool persist}) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await _pdfService.invoicePdfGenerate(
        widget.invoice!,
        widget.provider,
        business: _business,
        currencySymbol: Provider.of<CurrencyProvider>(context, listen: false)
            .currency
            .pdfSymbol,
        locale: 'en',
      );
      final invoiceId = widget.invoice?.invoiceId ?? 'draft';
      final dir = persist
          ? await getApplicationDocumentsDirectory()
          : await getTemporaryDirectory();
      final List<String> paths = [];
      int page = 0;
      await for (final raster in Printing.raster(bytes, dpi: 200)) {
        final png = await raster.toPng();
        final suffix = page == 0 ? '' : '_p${page + 1}';
        final filePath = '${dir.path}/Invoice_$invoiceId$suffix.png';
        await File(filePath).writeAsBytes(png, flush: true);
        paths.add(filePath);
        page++;
      }
      if (paths.isEmpty) return;
      if (persist) {
        await OpenFile.open(paths.first);
      } else {
        await SharePlus.instance
            .share(ShareParams(files: paths.map((p) => XFile(p)).toList()));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showExportOptions({required bool persist}) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(context.tr('export_format')),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _openPdf(persist: persist);
            },
            child: Text(context.tr('pdf_document')),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _exportAsImage(persist: persist);
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

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return CupertinoPageScaffold(
      backgroundColor: context.colors.background,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  closeButton(context),
                  const Spacer(),
                  Text(
                    context.tr('invoice_preview'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 34),
                ],
              ),
            ),
          ),
          Expanded(
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(platformBrightness: Brightness.light),
              child: Theme(
                data: ThemeData.light(useMaterial3: false),
                child: PdfPreview(
                  shouldRepaint: true,
                  scrollViewDecoration:
                      const BoxDecoration(color: Color(0xFFE8E8E8)),
                  pdfPreviewPageDecoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x29000000),
                          blurRadius: 6,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  dynamicLayout: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  allowPrinting: false,
                  allowSharing: false,
                  useActions: false,
                  canDebug: false,
                  enableScrollToPage: true,
                  previewPageMargin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.zero,
                  build: _buildPdf,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(top: BorderSide(color: context.colors.border)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    outlined: true,
                    txt: _generating
                        ? context.tr('saving')
                        : context.tr('download'),
                    onTap: _generating
                        ? null
                        : () => _showExportOptions(persist: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    txt: _generating
                        ? context.tr('opening')
                        : context.tr('send_invoice'),
                    onTap: _generating
                        ? null
                        : () => _showExportOptions(persist: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
