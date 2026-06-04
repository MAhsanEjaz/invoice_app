import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/bank_model.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

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


  Future<Uint8List> invoicePdfGenerate(
    InvoiceModel invoice,
    TemplatesColorsProvider? provider, {
    BusinessModel? business,
    String currencySymbol = '\$',
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

    switch (template) {
      case InvoiceTemplate.classic:
        pdf.addPage(_classicPage(invoice, business, accentColor, logoImage, items, subtotal, currencySymbol));
      case InvoiceTemplate.modern:
        pdf.addPage(_modernPage(invoice, business, accentColor, logoImage, items, subtotal, currencySymbol));
      case InvoiceTemplate.elegant:
        pdf.addPage(_elegantPage(invoice, business, accentColor, logoImage, items, subtotal, currencySymbol));
      case InvoiceTemplate.minimal:
        pdf.addPage(_minimalPage(invoice, business, accentColor, logoImage, items, subtotal, currencySymbol));
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 1 – CLASSIC
  // Full-width colored header, colored table header, alternating rows
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _classicPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
      ),
      build: (ctx) => [
        _classicHeader(invoice, business, accent, logo),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 0),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _billTo(invoice),
              pw.SizedBox(height: 28),
              _classicTable(items, accent, sym),
              pw.SizedBox(height: 20),
              _totals(subtotal, invoice.discount ?? 0, invoice.receivedAmount ?? 0, sym),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                _notes(invoice.notes!),
              ],
              if (invoice.bank != null) ...[
                pw.SizedBox(height: 20),
                _bankDetails(invoice.bank!),
              ],
              pw.SizedBox(height: 40),
              _footer(invoice.termsConditions),
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
  ) {
    final businessName = invoice.businessName ?? business?.businessName ?? 'Your Business';
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
                  child: pw.Image(logo, width: 52, height: 52, fit: pw.BoxFit.cover),
                ),
                pw.SizedBox(width: 14),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(businessName,
                      style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 18, color: PdfColors.white)),
                  pw.SizedBox(height: 3),
                  pw.Text('Invoice #${invoice.invoiceId ?? '001'}',
                      style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 11, color: PdfColors.white)),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('INVOICE',
                  style: pw.TextStyle(
                      font: pw.Font.helveticaBold(), fontSize: 30, color: PdfColors.white, letterSpacing: 2)),
              pw.SizedBox(height: 6),
              pw.Text('Date: ${invoice.date ?? ''}',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.white)),
              if (invoice.dueDate?.isNotEmpty ?? false)
                pw.Text('Due: ${invoice.dueDate}',
                    style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.white)),
              pw.Text('Status: ${invoice.invoiceStatus ?? 'Unpaid'}',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.white)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _classicTable(List items, PdfColor accent, String sym) {
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
            _th('DESCRIPTION'),
            _th('QTY', align: pw.Alignment.center),
            _th('UNIT PRICE', align: pw.Alignment.centerRight),
            _th('AMOUNT', align: pw.Alignment.centerRight),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isOdd ? rowAlt : PdfColors.white),
            children: [
              _td(item.itemName ?? ''),
              _td(qty.toString(), align: pw.Alignment.center),
              _td('$sym${unitPrice.toStringAsFixed(2)}', align: pw.Alignment.centerRight),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}', align: pw.Alignment.centerRight, bold: true),
            ],
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 2 – MODERN
  // Split header: white left panel + colored right panel, line-only table
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _modernPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
      ),
      build: (ctx) => [
        _modernHeader(invoice, business, accent, logo),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _billTo(invoice),
              pw.SizedBox(height: 28),
              _modernTable(items, accent, sym),
              pw.SizedBox(height: 20),
              _modernTotals(subtotal, invoice.discount ?? 0, invoice.receivedAmount ?? 0, sym, accent),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                _notes(invoice.notes!),
              ],
              if (invoice.bank != null) ...[
                pw.SizedBox(height: 20),
                _bankDetails(invoice.bank!),
              ],
              pw.SizedBox(height: 40),
              _footer(invoice.termsConditions),
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
  ) {
    final businessName = invoice.businessName ?? business?.businessName ?? 'Your Business';
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Left: white panel with business info
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.fromLTRB(40, 32, 24, 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (logo != null) ...[
                  pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(logo, width: 56, height: 56, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(height: 12),
                ],
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 20,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 40,
                  height: 3,
                  color: accent,
                ),
              ],
            ),
          ),
        ),

        // Right: accent-colored panel with INVOICE info
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            color: accent,
            padding: const pw.EdgeInsets.fromLTRB(24, 32, 40, 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 26,
                    color: PdfColors.white,
                    letterSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 10),
                _modernInfoLine('No.', '#${invoice.invoiceId ?? '001'}'),
                _modernInfoLine('Date', invoice.date ?? ''),
                if (invoice.dueDate?.isNotEmpty ?? false)
                  _modernInfoLine('Due', invoice.dueDate!),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    invoice.invoiceStatus ?? 'Unpaid',
                    style: pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 9,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _modernInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            '$label  ',
            style: pw.TextStyle(
              font: pw.Font.helvetica(),
              fontSize: 9,
              color: const PdfColor(0.85, 0.85, 0.85),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: pw.Font.helveticaBold(),
              fontSize: 9,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _modernTable(List items, PdfColor accent, String sym) {
    return pw.Table(
      border: pw.TableBorder(
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
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
            border: pw.Border(bottom: pw.BorderSide(color: accent, width: 2)),
          ),
          children: [
            _modernTh('DESCRIPTION', accent),
            _modernTh('QTY', accent, align: pw.Alignment.center),
            _modernTh('UNIT PRICE', accent, align: pw.Alignment.centerRight),
            _modernTh('AMOUNT', accent, align: pw.Alignment.centerRight),
          ],
        ),
        ...items.map((item) {
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              _td(item.itemName ?? ''),
              _td(qty.toString(), align: pw.Alignment.center),
              _td('$sym${unitPrice.toStringAsFixed(2)}', align: pw.Alignment.centerRight),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}', align: pw.Alignment.centerRight, bold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _modernTh(String text, PdfColor accent, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: pw.Font.helveticaBold(),
          fontSize: 8,
          color: accent,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  pw.Widget _modernTotals(
    double subtotal,
    double discount,
    double received,
    String sym,
    PdfColor accent,
  ) {
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final balanceDue = (total - received).clamp(0.0, double.infinity);
    final hasDiscount = discount > 0;
    final hasReceived = received > 0;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 240,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', '$sym${subtotal.toStringAsFixed(2)}'),
            if (hasDiscount)
              _totalRow('Discount', '-$sym${discount.toStringAsFixed(2)}', valueColor: PdfColors.orange800),
            if (hasReceived)
              _totalRow('Received', '($sym${received.toStringAsFixed(2)})', valueColor: PdfColors.green700),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    hasDiscount || hasReceived ? 'BALANCE DUE' : 'TOTAL DUE',
                    style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11, color: PdfColors.white),
                  ),
                  pw.Text(
                    '$sym${(hasDiscount || hasReceived ? balanceDue : subtotal).toStringAsFixed(2)}',
                    style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 13, color: PdfColors.white),
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
  // Very dark header, white text, no alternating rows, premium feel
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _elegantPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
  ) {
    final dark = _darken(accent, 0.72);

    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
      ),
      build: (ctx) => [
        _elegantHeader(invoice, business, accent, dark, logo),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _elegantBillTo(invoice, accent),
              pw.SizedBox(height: 28),
              _elegantTable(items, accent, dark, sym),
              pw.SizedBox(height: 20),
              _totals(subtotal, invoice.discount ?? 0, invoice.receivedAmount ?? 0, sym),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                _notes(invoice.notes!),
              ],
              if (invoice.bank != null) ...[
                pw.SizedBox(height: 20),
                _bankDetails(invoice.bank!),
              ],
              pw.SizedBox(height: 40),
              _footer(invoice.termsConditions),
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
  ) {
    final businessName = invoice.businessName ?? business?.businessName ?? 'Your Business';
    return pw.Container(
      color: dark,
      child: pw.Column(
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
                        child: pw.Image(logo, width: 56, height: 56, fit: pw.BoxFit.cover),
                      ),
                      pw.SizedBox(width: 16),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          businessName,
                          style: pw.TextStyle(
                            font: pw.Font.helveticaBold(),
                            fontSize: 20,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Invoice #${invoice.invoiceId ?? '001'}',
                          style: pw.TextStyle(
                            font: pw.Font.helvetica(),
                            fontSize: 10,
                            color: const PdfColor(0.72, 0.72, 0.72),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        font: pw.Font.helveticaBold(),
                        fontSize: 28,
                        color: accent,
                        letterSpacing: 4,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Date: ${invoice.date ?? ''}',
                      style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: const PdfColor(0.85, 0.85, 0.85)),
                    ),
                    if (invoice.dueDate?.isNotEmpty ?? false)
                      pw.Text(
                        'Due: ${invoice.dueDate}',
                        style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: const PdfColor(0.85, 0.85, 0.85)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Accent bottom stripe
          pw.Container(height: 3, color: accent),
        ],
      ),
    );
  }

  pw.Widget _elegantBillTo(InvoiceModel invoice, PdfColor accent) {
    final client = (invoice.clients?.isNotEmpty ?? false) ? invoice.clients!.first : null;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: 3, height: 60, color: accent),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BILL TO',
              style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 8,
                color: PdfColors.grey600,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 6),
            if (client != null) ...[
              pw.Text(client.name ?? '',
                  style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 14, color: PdfColors.black)),
              if (client.email?.isNotEmpty ?? false)
                pw.Text(client.email!,
                    style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey600)),
              if (client.phone?.isNotEmpty ?? false)
                pw.Text(client.phone!,
                    style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey600)),
              if (client.address?.isNotEmpty ?? false)
                pw.Text(client.address!,
                    style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey600)),
            ],
          ],
        ),
      ],
    );
  }

  pw.Widget _elegantTable(List items, PdfColor accent, PdfColor dark, String sym) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
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
            _th('DESCRIPTION'),
            _th('QTY', align: pw.Alignment.center),
            _th('UNIT PRICE', align: pw.Alignment.centerRight),
            _th('AMOUNT', align: pw.Alignment.centerRight),
          ],
        ),
        ...items.map((item) {
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              _td(item.itemName ?? ''),
              _td(qty.toString(), align: pw.Alignment.center),
              _td('$sym${unitPrice.toStringAsFixed(2)}', align: pw.Alignment.centerRight),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}', align: pw.Alignment.centerRight, bold: true),
            ],
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 4 – MINIMAL
  // Thin top accent line, plain text header, line-only table, lots of space
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Page _minimalPage(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accent,
    pw.MemoryImage? logo,
    List items,
    double subtotal,
    String sym,
  ) {
    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
      ),
      build: (ctx) => [
        // Top accent stripe
        pw.Container(height: 4, color: accent),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(48, 36, 48, 0),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _minimalHeader(invoice, business, accent, logo),
              pw.SizedBox(height: 36),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.SizedBox(height: 28),
              _billTo(invoice),
              pw.SizedBox(height: 32),
              _minimalTable(items, accent, sym),
              pw.SizedBox(height: 24),
              _totals(subtotal, invoice.discount ?? 0, invoice.receivedAmount ?? 0, sym),
              if (invoice.notes?.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 24),
                _notes(invoice.notes!),
              ],
              if (invoice.bank != null) ...[
                pw.SizedBox(height: 24),
                _bankDetails(invoice.bank!),
              ],
              pw.SizedBox(height: 48),
              _footer(invoice.termsConditions),
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
  ) {
    final businessName = invoice.businessName ?? business?.businessName ?? 'Your Business';
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
                child: pw.Image(logo, width: 52, height: 52, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(width: 14),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    font: pw.Font.helveticaBold(),
                    fontSize: 22,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Invoice #${invoice.invoiceId ?? '001'}',
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 11, color: accent),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              invoice.date ?? '',
              style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 11, color: PdfColors.grey700),
            ),
            if (invoice.dueDate?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Due ${invoice.dueDate}',
                style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11, color: PdfColors.grey800),
              ),
            ],
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: accent, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                invoice.invoiceStatus ?? 'Unpaid',
                style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 9, color: accent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _minimalTable(List items, PdfColor accent, String sym) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: accent, width: 1.5),
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
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
            _minimalTh('DESCRIPTION', accent),
            _minimalTh('QTY', accent, align: pw.Alignment.center),
            _minimalTh('UNIT PRICE', accent, align: pw.Alignment.centerRight),
            _minimalTh('AMOUNT', accent, align: pw.Alignment.centerRight),
          ],
        ),
        ...items.map((item) {
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          return pw.TableRow(
            children: [
              _td(item.itemName ?? ''),
              _td(qty.toString(), align: pw.Alignment.center),
              _td('$sym${unitPrice.toStringAsFixed(2)}', align: pw.Alignment.centerRight),
              _td('$sym${(unitPrice * qty).toStringAsFixed(2)}', align: pw.Alignment.centerRight, bold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _minimalTh(String text, PdfColor accent, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: pw.Font.helveticaBold(),
          fontSize: 8,
          color: PdfColors.grey600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Widget _billTo(InvoiceModel invoice) {
    final client = (invoice.clients?.isNotEmpty ?? false) ? invoice.clients!.first : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BILL TO',
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 9,
            color: PdfColors.grey700,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 6),
        if (client != null) ...[
          pw.Text(client.name ?? '',
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 13, color: PdfColors.black)),
          if (client.email?.isNotEmpty ?? false)
            pw.Text(client.email!,
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey700)),
          if (client.phone?.isNotEmpty ?? false)
            pw.Text(client.phone!,
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey700)),
          if (client.address?.isNotEmpty ?? false)
            pw.Text(client.address!,
                style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey700)),
        ],
      ],
    );
  }

  pw.Widget _th(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: pw.Font.helveticaBold(),
          fontSize: 9,
          color: PdfColors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _td(String text, {pw.Alignment align = pw.Alignment.centerLeft, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
          fontSize: 10,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _totals(double subtotal, double discount, double received, String sym) {
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
            _totalRow('Subtotal', '$sym${subtotal.toStringAsFixed(2)}'),
            if (hasDiscount)
              _totalRow('Discount', '-$sym${discount.toStringAsFixed(2)}', valueColor: PdfColors.orange800),
            if (hasReceived)
              _totalRow('Received', '($sym${received.toStringAsFixed(2)})', valueColor: PdfColors.green700),
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            ),
            _totalRow(
              hasAdjustment ? 'BALANCE DUE' : 'TOTAL DUE',
              '$sym${(hasAdjustment ? balanceDue : subtotal).toStringAsFixed(2)}',
              isBold: true,
              fontSize: 13,
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
  }) {
    final labelColor = isBold ? PdfColors.black : PdfColors.grey700;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
                  fontSize: fontSize,
                  color: labelColor)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
                  fontSize: fontSize,
                  color: valueColor ?? labelColor)),
        ],
      ),
    );
  }

  pw.Widget _notes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('NOTES',
            style: pw.TextStyle(
                font: pw.Font.helveticaBold(), fontSize: 9, color: PdfColors.grey700, letterSpacing: 1.5)),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.973, 0.980, 0.988),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Text(notes,
              style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey800)),
        ),
      ],
    );
  }

  pw.Widget _bankDetails(BankModel bank) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PAYMENT DETAILS',
            style: pw.TextStyle(
                font: pw.Font.helveticaBold(), fontSize: 9, color: PdfColors.grey700, letterSpacing: 1.5)),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.973, 0.980, 0.988),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _bankRow('Bank', bank.bankName ?? ''),
              pw.SizedBox(height: 4),
              _bankRow('Account Title', bank.title ?? ''),
              pw.SizedBox(height: 4),
              _bankRow('Account Number', bank.accountNumber ?? '', bold: true),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _bankRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text('$label:',
              style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 10, color: PdfColors.grey700)),
        ),
        pw.Expanded(
          child: pw.Text(value,
              style: pw.TextStyle(
                  font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
                  fontSize: 10,
                  color: PdfColors.black)),
        ),
      ],
    );
  }

  pw.Widget _footer(String? termsConditions) {
    final hasTerms = termsConditions?.isNotEmpty ?? false;
    final signatureWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('Authorized Signature',
            style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 28),
        pw.Container(
          width: 130,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5)),
          ),
        ),
      ],
    );

    if (!hasTerms) return pw.Align(alignment: pw.Alignment.centerRight, child: signatureWidget);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TERMS & CONDITIONS',
                  style: pw.TextStyle(
                      font: pw.Font.helveticaBold(), fontSize: 8, letterSpacing: 1, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(termsConditions!,
                  style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        signatureWidget,
      ],
    );
  }
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
        currencySymbol:
            Provider.of<CurrencyProvider>(context, listen: false).currency.pdfSymbol,
      );

  Future<void> _openPdf({required bool persist}) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await _pdfService.invoicePdfGenerate(
        widget.invoice!,
        widget.provider,
        business: _business,
        currencySymbol:
            Provider.of<CurrencyProvider>(context, listen: false).currency.pdfSymbol,
      );
      final dir = persist ? await getApplicationDocumentsDirectory() : await getTemporaryDirectory();
      final invoiceId = widget.invoice?.invoiceId ?? 'draft';
      final file = File('${dir.path}/Invoice_$invoiceId.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kBackground,
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
                    'Invoice Preview',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 34),
                ],
              ),
            ),
          ),
          Expanded(
            child: PdfPreview(
              shouldRepaint: true,
              scrollViewDecoration: const BoxDecoration(color: kBackground),
              dynamicLayout: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowPrinting: false,
              allowSharing: false,
              useActions: false,
              canDebug: false,
              enableScrollToPage: true,
              previewPageMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.zero,
              build: _buildPdf,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: kSurface,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    outlined: true,
                    txt: _generating ? 'Saving…' : 'Download',
                    onTap: _generating ? null : () => _openPdf(persist: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    txt: _generating ? 'Opening…' : 'Send Invoice',
                    onTap: _generating ? null : () => _openPdf(persist: false),
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
