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

  // Loads NotoSansDevanagari-Regular.ttf from assets (for Hindi)
  static Future<pw.Font?> devanagari() async {
    if (_devanagari != null) return _devanagari;
    try {
      final data = await rootBundle.load(
          'assets/fonts/NotoSansDevanagari-Regular.ttf');
      _devanagari = pw.Font.ttf(data);
      return _devanagari;
    } catch (_) {
      return null;
    }
  }

  // Loads NotoNaskhArabic-Regular.ttf from assets (for Urdu)
  static Future<pw.Font?> arabic() async {
    if (_arabic != null) return _arabic;
    try {
      final data = await rootBundle.load(
          'assets/fonts/NotoNaskhArabic-Regular.ttf');
      _arabic = pw.Font.ttf(data);
      return _arabic;
    } catch (_) {
      return null;
    }
  }
}

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

    // Load locale-appropriate font for PDF text
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 1 – CLASSIC
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _classicPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
    _PdfLabels l,
    pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        textDirection: l.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
      build: (ctx) => [
        _classicHeader(invoice, business, accent, logo, l, font),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 28),
              _classicTable(items, accent, sym, l, font),
              pw.SizedBox(height: 20),
              _totals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, l, font),
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
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final businessName = invoice.businessName ??
        business?.businessName ??
        l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    return pw.Container(
      color: accent,
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(logo,
                      width: 52, height: 52, fit: pw.BoxFit.cover),
                ),
                pw.SizedBox(width: 14),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(businessName,
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 18,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 11,
                          color: PdfColors.white)),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(_docTypeTitle(invoice.documentType, l),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 30,
                      color: PdfColors.white,
                      letterSpacing: l.isRtl ? 0 : 2)),
              pw.SizedBox(height: 6),
              pw.Text('${l.t('pdf_date')}: ${invoice.date ?? ''}',
                  style: pw.TextStyle(
                      font: regular, fontSize: 10, color: PdfColors.white)),
              if (invoice.dueDate?.isNotEmpty ?? false)
                pw.Text('${l.t('pdf_due')}: ${invoice.dueDate}',
                    style: pw.TextStyle(
                        font: regular,
                        fontSize: 10,
                        color: PdfColors.white)),
              pw.Text(
                  '${l.t('pdf_status')}: ${_localizedStatus(invoice.invoiceStatus, l)}',
                  style: pw.TextStyle(
                      font: regular, fontSize: 10, color: PdfColors.white)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _classicTable(List items, PdfColor accent, String sym,
      _PdfLabels l, pw.Font? font) {
    const rowAlt = PdfColor(0.973, 0.980, 0.988);
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accent),
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
                color: i.isOdd ? rowAlt : PdfColors.white),
            children: [
              _td(item.itemName ?? '', font: font),
              _td(qty.toString(), align: pw.Alignment.center, font: font),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 2 – MODERN
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _modernPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
    _PdfLabels l,
    pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        textDirection: l.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
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
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final businessName = invoice.businessName ??
        business?.businessName ??
        l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.fromLTRB(40, 32, 24, 32),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (logo != null) ...[
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(logo,
                        width: 56, height: 56, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(height: 12),
                ],
                pw.Text(businessName,
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 20,
                        color: PdfColors.grey900)),
                pw.SizedBox(height: 6),
                pw.Container(width: 40, height: 3, color: accent),
              ],
            ),
          ),
        ),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            color: accent,
            padding: const pw.EdgeInsets.fromLTRB(24, 32, 40, 32),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(_docTypeTitle(invoice.documentType, l),
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 26,
                        color: PdfColors.white,
                        letterSpacing: l.isRtl ? 0 : 3)),
                pw.SizedBox(height: 10),
                _modernInfoLine(l.t('pdf_no'),
                    '#${invoice.invoiceId ?? '001'}', regular),
                _modernInfoLine(
                    l.t('pdf_date'), invoice.date ?? '', regular),
                if (invoice.dueDate?.isNotEmpty ?? false)
                  _modernInfoLine(
                      l.t('pdf_due'), invoice.dueDate!, regular),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    _localizedStatus(invoice.invoiceStatus, l),
                    style: pw.TextStyle(
                        font: bold, fontSize: 9, color: accent),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('$label  ',
              style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: const PdfColor(0.85, 0.85, 0.85))),
          pw.Text(value,
              style: pw.TextStyle(
                  font: regular,
                  fontSize: 9,
                  color: PdfColors.white)),
        ],
      ),
    );
  }

  pw.Widget _modernTable(List items, PdfColor accent, String sym,
      _PdfLabels l, pw.Font? font) {
    return pw.Table(
      border: pw.TableBorder(
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside:
            const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
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
                bottom: pw.BorderSide(color: accent, width: 2)),
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
        ...items.map((item) {
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              _td(item.itemName ?? '', font: font),
              _td(qty.toString(), align: pw.Alignment.center, font: font),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font ?? pw.Font.helveticaBold(),
              fontSize: 8,
              color: accent,
              letterSpacing: 0.8)),
    );
  }

  pw.Widget _modernTotals(
    double subtotal,
    double discount,
    double received,
    String sym,
    PdfColor accent,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final bold = font ?? pw.Font.helveticaBold();

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 240,
        child: pw.Column(
          children: [
            _totalRow(l.t('pdf_subtotal'),
                '$sym${subtotal.toStringAsFixed(2)}', font: font),
            if (hasDiscount)
              _totalRow(l.t('pdf_discount'),
                  '-$sym${discount.toStringAsFixed(2)}',
                  valueColor: PdfColors.orange800, font: font),
            if (hasReceived)
              _totalRow(l.t('pdf_received'),
                  '($sym${received.toStringAsFixed(2)})',
                  valueColor: PdfColors.green700, font: font),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    hasDiscount || hasReceived
                        ? l.t('pdf_balance_due')
                        : l.t('pdf_total_due'),
                    style: pw.TextStyle(
                        font: bold, fontSize: 11, color: PdfColors.white),
                  ),
                  pw.Text(
                    '$sym${(hasDiscount || hasReceived ? balanceDue : subtotal).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        font: bold, fontSize: 13, color: PdfColors.white),
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
  // TEMPLATE 3 – ELEGANT
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _elegantPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final dark = _darken(accent, 0.72);

    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        textDirection: l.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
      build: (ctx) => [
        _elegantHeader(invoice, business, accent, dark, logo, l, font),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 28),
              _elegantTable(items, accent, dark, sym, l, font),
              pw.SizedBox(height: 20),
              _totals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, l, font),
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
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    PdfColor dark,
    pw.MemoryImage? logo,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final businessName = invoice.businessName ??
        business?.businessName ??
        l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    return pw.Container(
      color: dark,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(40, 36, 40, 28),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null) ...[
                      pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Image(logo,
                            width: 56, height: 56, fit: pw.BoxFit.cover),
                      ),
                      pw.SizedBox(width: 16),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(businessName,
                            style: pw.TextStyle(
                                font: bold,
                                fontSize: 20,
                                color: PdfColors.white)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                            '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                            style: pw.TextStyle(
                                font: regular,
                                fontSize: 10,
                                color:
                                    const PdfColor(0.72, 0.72, 0.72))),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(_docTypeTitle(invoice.documentType, l),
                        style: pw.TextStyle(
                            font: bold,
                            fontSize: 28,
                            color: accent,
                            letterSpacing: l.isRtl ? 0 : 4)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        '${l.t('pdf_date')}: ${invoice.date ?? ''}',
                        style: pw.TextStyle(
                            font: regular,
                            fontSize: 10,
                            color:
                                const PdfColor(0.85, 0.85, 0.85))),
                    if (invoice.dueDate?.isNotEmpty ?? false)
                      pw.Text(
                          '${l.t('pdf_due')}: ${invoice.dueDate}',
                          style: pw.TextStyle(
                              font: regular,
                              fontSize: 10,
                              color:
                                  const PdfColor(0.85, 0.85, 0.85))),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(height: 3, color: accent),
        ],
      ),
    );
  }


  pw.Widget _elegantTable(List items, PdfColor accent, PdfColor dark,
      String sym, _PdfLabels l, pw.Font? font) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside:
            const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: dark),
          children: [
            _th(l.t('pdf_description'), font: font),
            _th(l.t('pdf_qty'), align: pw.Alignment.center, font: font),
            _th(l.t('pdf_unit_price'),
                align: pw.Alignment.centerRight, font: font),
            _th(l.t('pdf_amount'),
                align: pw.Alignment.centerRight, font: font),
          ],
        ),
        ...items.map((item) {
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              _td(item.itemName ?? '', font: font),
              _td(qty.toString(), align: pw.Alignment.center, font: font),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 4 – MINIMAL
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _minimalPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
    _PdfLabels l,
    pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        textDirection: l.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
      build: (ctx) => [
        pw.Container(height: 4, color: accent),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(48, 36, 48, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _minimalHeader(invoice, business, accent, logo, l, font),
              pw.SizedBox(height: 36),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 28),
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 32),
              _minimalTable(items, accent, sym, l, font),
              pw.SizedBox(height: 24),
              _totals(subtotal, invoice.discount ?? 0,
                  invoice.receivedAmount ?? 0, sym, l, font),
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
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final businessName = invoice.businessName ??
        business?.businessName ??
        l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null) ...[
              pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(logo,
                    width: 52, height: 52, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(width: 14),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(businessName,
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 22,
                        color: PdfColors.grey900)),
                pw.SizedBox(height: 4),
                pw.Text(
                    '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                    style: pw.TextStyle(
                        font: regular, fontSize: 11, color: accent)),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(invoice.date ?? '',
                style: pw.TextStyle(
                    font: regular,
                    fontSize: 11,
                    color: PdfColors.grey700)),
            if (invoice.dueDate?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 4),
              pw.Text('${l.t('pdf_due')} ${invoice.dueDate}',
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 11,
                      color: PdfColors.grey800)),
            ],
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: accent, width: 1),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                _localizedStatus(invoice.invoiceStatus, l),
                style: pw.TextStyle(
                    font: bold, fontSize: 9, color: accent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _minimalTable(List items, PdfColor accent, String sym,
      _PdfLabels l, pw.Font? font) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: accent, width: 1.5),
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside:
            const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
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
            _minimalTh(l.t('pdf_description'), accent, font: font),
            _minimalTh(l.t('pdf_qty'), accent,
                align: pw.Alignment.center, font: font),
            _minimalTh(l.t('pdf_unit_price'), accent,
                align: pw.Alignment.centerRight, font: font),
            _minimalTh(l.t('pdf_amount'), accent,
                align: pw.Alignment.centerRight, font: font),
          ],
        ),
        ...items.map((item) {
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              _td(item.itemName ?? '', font: font),
              _td(qty.toString(), align: pw.Alignment.center, font: font),
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

  pw.Widget _minimalTh(String text, PdfColor accent,
      {pw.Alignment align = pw.Alignment.centerLeft, pw.Font? font}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font ?? pw.Font.helveticaBold(),
              fontSize: 8,
              color: PdfColors.grey600,
              letterSpacing: 0.8)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 5 – WAVE
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _wavePage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
    _PdfLabels l,
    pw.Font? font,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        textDirection: l.isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
      build: (ctx) => [
        _waveHeader(invoice, business, accent, logo, l, font),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 20, 40, 0),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _waveInfoCards(invoice, accent, l, font),
              pw.SizedBox(height: 24),
              _fromToSection(invoice, business, l, font),
              pw.SizedBox(height: 24),
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
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    _PdfLabels l,
    pw.Font? font,
  ) {
    // waveH = how far the center of the arch dips below the sides
    const waveH = 44.0;
    const contentH = 108.0;
    const totalH = contentH + waveH;

    final businessName = invoice.businessName ??
        business?.businessName ??
        l.t('pdf_your_business');
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();

    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        // pw.CustomPainter is typedef Function(PdfGraphics, PdfPoint).
        // Coordinate system: (0,0)=top-left, y increases downward.
        // The accent area fills the top; the arch dips toward the bottom center.
        const waveArc = 44.0;
        final w = size.x;
        final h = size.y;
        canvas
          ..setFillColor(accent)
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w, h - waveArc)
          ..curveTo(w * 0.75, h, w * 0.25, h, 0, h - waveArc)
          ..closePath()
          ..fillPath();
      },
      child: pw.Container(
        width: double.infinity,
        height: totalH,
        padding: pw.EdgeInsets.fromLTRB(40, 28, 40, waveH + 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Left: logo + business name
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null) ...[
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(logo,
                        width: 48, height: 48, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(width: 14),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                          font: bold, fontSize: 18, color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${_docTypeNo(invoice.documentType, l)}${invoice.invoiceId ?? '001'}',
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: const PdfColor(0.88, 0.88, 0.94)),
                    ),
                  ],
                ),
              ],
            ),
            // Right: document title
            pw.Text(
              _docTypeTitle(invoice.documentType, l),
              style: pw.TextStyle(
                font: bold,
                fontSize: 28,
                color: PdfColors.white,
                letterSpacing: l.isRtl ? 0 : 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _waveInfoCards(
    InvoiceModel invoice,
    PdfColor accent,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    final isInvoice =
        invoice.documentType == null || invoice.documentType == 'Invoice';

    pw.Widget card(String label, String value, {bool isStatus = false}) {
      final isPaid = invoice.invoiceStatus == 'Paid';
      final statusColor = isPaid
          ? const PdfColor(0.09, 0.64, 0.29)
          : const PdfColor(0.85, 0.47, 0.08);

      return pw.Expanded(
        child: pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                    font: regular,
                    fontSize: 7,
                    color: PdfColors.grey500,
                    letterSpacing: 0.6),
              ),
              pw.SizedBox(height: 5),
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
                            fontSize: 11,
                            color: statusColor)),
                  ],
                )
              else
                pw.Text(value,
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 11,
                        color: PdfColors.grey800)),
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
        card(l.t('pdf_date').toUpperCase(), invoice.date ?? '-'),
        pw.SizedBox(width: 10),
        card(
          l.t('pdf_due').toUpperCase(),
          (invoice.dueDate?.isNotEmpty ?? false) ? invoice.dueDate! : '-',
        ),
        pw.SizedBox(width: 10),
        card(l.t('pdf_status').toUpperCase(), statusLabel, isStatus: true),
      ],
    );
  }

  pw.Widget _waveTable(List items, PdfColor accent, String sym,
      _PdfLabels l, pw.Font? font) {
    return pw.Table(
      border: pw.TableBorder(
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside:
            const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
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
            border:
                pw.Border(bottom: pw.BorderSide(color: accent, width: 1.5)),
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
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              _td(item.itemName ?? '', font: font),
              _td(qty.toString(), align: pw.Alignment.center, font: font),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: font ?? pw.Font.helveticaBold(),
              fontSize: 8,
              color: accent,
              letterSpacing: 0.8)),
    );
  }

  pw.Widget _waveTotals(
    double subtotal,
    double discount,
    double received,
    String sym,
    PdfColor accent,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdjustment = hasDiscount || hasReceived;
    final bold = font ?? pw.Font.helveticaBold();

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 260,
        child: pw.Column(
          children: [
            // Subtotal / discount / received section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.96, 0.97, 0.99),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(10),
                  topRight: pw.Radius.circular(10),
                ),
              ),
              child: pw.Column(
                children: [
                  _totalRow(l.t('pdf_subtotal'),
                      '$sym${subtotal.toStringAsFixed(2)}',
                      font: font),
                  if (hasDiscount) ...[
                    pw.SizedBox(height: 4),
                    _totalRow(l.t('pdf_discount'),
                        '-$sym${discount.toStringAsFixed(2)}',
                        valueColor: PdfColors.orange700, font: font),
                  ],
                  if (hasReceived) ...[
                    pw.SizedBox(height: 4),
                    _totalRow(l.t('pdf_received'),
                        '($sym${received.toStringAsFixed(2)})',
                        valueColor: PdfColors.green700, font: font),
                  ],
                ],
              ),
            ),
            // Total due section with accent background
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(10),
                  bottomRight: pw.Radius.circular(10),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    hasAdjustment
                        ? l.t('pdf_balance_due')
                        : l.t('pdf_total_due'),
                    style: pw.TextStyle(
                        font: bold, fontSize: 11, color: PdfColors.white),
                  ),
                  pw.Text(
                    '$sym${(hasAdjustment ? balanceDue : subtotal).toStringAsFixed(2)}',
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
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Widget _fromToSection(
    InvoiceModel invoice,
    BusinessModel? business,
    _PdfLabels l,
    pw.Font? font,
  ) {
    final client =
        (invoice.clients?.isNotEmpty ?? false) ? invoice.clients!.first : null;
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
              pw.Text(l.t('pdf_from'),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 9,
                      color: PdfColors.grey700,
                      letterSpacing: 1.5)),
              pw.SizedBox(height: 6),
              pw.Text(businessName,
                  style: pw.TextStyle(
                      font: bold, fontSize: 13, color: PdfColors.black)),
              if (bank != null) ...[
                pw.SizedBox(height: 4),
                if (bank.bankName?.isNotEmpty ?? false)
                  pw.Text(bank.bankName!,
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                if (bank.title?.isNotEmpty ?? false)
                  pw.Text(bank.title!,
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                if (bank.accountNumber?.isNotEmpty ?? false)
                  pw.Text(bank.accountNumber!,
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 10,
                          color: PdfColors.grey800)),
              ],
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(l.t('pdf_invoice_to'),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 9,
                      color: PdfColors.grey700,
                      letterSpacing: 1.5)),
              pw.SizedBox(height: 6),
              if (client != null) ...[
                pw.Text(client.name ?? '',
                    style: pw.TextStyle(
                        font: bold, fontSize: 13, color: PdfColors.black)),
                if (client.email?.isNotEmpty ?? false)
                  pw.Text(client.email!,
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                if (client.phone?.isNotEmpty ?? false)
                  pw.Text(client.phone!,
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: PdfColors.grey700)),
                if (client.address?.isNotEmpty ?? false)
                  pw.Text(client.address!,
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: PdfColors.grey700)),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      alignment: align,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: bold
                  ? (font ?? pw.Font.helveticaBold())
                  : (font ?? pw.Font.helvetica()),
              fontSize: 10,
              color: PdfColors.black)),
    );
  }

  pw.Widget _totals(double subtotal, double discount, double received,
      String sym, _PdfLabels l, pw.Font? font) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;
    final hasAdjustment = hasDiscount || hasReceived;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            _totalRow(l.t('pdf_subtotal'),
                '$sym${subtotal.toStringAsFixed(2)}',
                font: font),
            if (hasDiscount)
              _totalRow(l.t('pdf_discount'),
                  '-$sym${discount.toStringAsFixed(2)}',
                  valueColor: PdfColors.orange800, font: font),
            if (hasReceived)
              _totalRow(l.t('pdf_received'),
                  '($sym${received.toStringAsFixed(2)})',
                  valueColor: PdfColors.green700, font: font),
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            ),
            _totalRow(
              hasAdjustment ? l.t('pdf_balance_due') : l.t('pdf_total_due'),
              '$sym${(hasAdjustment ? balanceDue : subtotal).toStringAsFixed(2)}',
              isBold: true,
              fontSize: 13,
              font: font,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
    PdfColor? valueColor,
    pw.Font? font,
  }) {
    final labelColor = isBold ? PdfColors.black : PdfColors.grey700;
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: isBold ? bold : regular,
                  fontSize: fontSize,
                  color: labelColor)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: isBold ? bold : regular,
                  fontSize: fontSize,
                  color: valueColor ?? labelColor)),
        ],
      ),
    );
  }

  pw.Widget _notes(String notes, _PdfLabels l, pw.Font? font) {
    final regular = font ?? pw.Font.helvetica();
    final bold = font ?? pw.Font.helveticaBold();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(l.t('pdf_notes'),
            style: pw.TextStyle(
                font: bold,
                fontSize: 9,
                color: PdfColors.grey700,
                letterSpacing: 1.5)),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.973, 0.980, 0.988),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Text(notes,
              style: pw.TextStyle(
                  font: regular, fontSize: 10, color: PdfColors.grey800)),
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
                font: regular, fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 28),
        pw.Container(
          width: 130,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(
                    color: PdfColors.grey500, width: 0.5)),
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
              pw.Text(l.t('pdf_terms'),
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 8,
                      letterSpacing: 1,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(termsConditions!,
                  style: pw.TextStyle(
                      font: regular,
                      fontSize: 9,
                      color: PdfColors.grey600)),
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
        locale:
            Provider.of<LocaleProvider>(context, listen: false).languageCode,
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
        locale:
            Provider.of<LocaleProvider>(context, listen: false).languageCode,
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
        locale:
            Provider.of<LocaleProvider>(context, listen: false).languageCode,
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
    return CupertinoPageScaffold(
      backgroundColor: context.colors.background,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            child: Theme(
              data: ThemeData.light(),
              child: PdfPreview(
                shouldRepaint: true,
                scrollViewDecoration:
                    const BoxDecoration(color: Color(0xFFE8E8E8)),
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
