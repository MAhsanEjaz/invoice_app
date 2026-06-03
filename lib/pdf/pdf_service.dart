import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
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
  /// Converts a Flutter [Color] to a [PdfColor].
  PdfColor _toPdf(Color color) => PdfColor(
        color.r.toDouble(),
        color.g.toDouble(),
        color.b.toDouble(),
      );

  Future<Uint8List> invoicePdfGenerate(
    InvoiceModel invoice,
    TemplatesColorsProvider? provider, {
    BusinessModel? business,
  }) async {
    final pdf = pw.Document();

    // Accent color: from selected template color, fallback to default teal
    final accentColor =
        provider != null ? _toPdf(provider.color) : PdfColor(0.051, 0.451, 0.467);

    // ── Calculate totals from actual invoice data ───────────────────────────
    final items = invoice.items ?? [];
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + ((item.price?.toDouble() ?? 0) * (item.qty ?? 1)),
    );

    // ── Optionally load business logo ────────────────────────────────────────
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

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
        ),
        build: (ctx) => [
          _buildHeader(invoice, business, accentColor, logoImage),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildBillTo(invoice),
                pw.SizedBox(height: 28),
                _buildItemsTable(items, accentColor),
                pw.SizedBox(height: 20),
                _buildTotals(subtotal, invoice.receivedAmount ?? 0),
                if (invoice.notes?.isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 20),
                  _buildNotes(invoice.notes!),
                ],
                pw.SizedBox(height: 40),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Header: accent background with business info left, invoice title right ──
  pw.Widget _buildHeader(
    InvoiceModel invoice,
    BusinessModel? business,
    PdfColor accentColor,
    pw.MemoryImage? logo,
  ) {
    final businessName = business?.businessName ?? 'Your Business';

    return pw.Container(
      color: accentColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: optional logo + business name
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
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(
                      font: pw.Font.helveticaBold(),
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Invoice #${invoice.invoiceId ?? '001'}',
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: INVOICE label + date
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  fontSize: 30,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Date: ${invoice.date ?? ''}',
                style: pw.TextStyle(
                  font: pw.Font.helvetica(),
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Status: ${invoice.invoiceStatus ?? 'Unpaid'}',
                style: pw.TextStyle(
                  font: pw.Font.helvetica(),
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bill To ────────────────────────────────────────────────────────────────
  pw.Widget _buildBillTo(InvoiceModel invoice) {
    final client =
        (invoice.clients?.isNotEmpty ?? false) ? invoice.clients!.first : null;

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
          pw.Text(
            client.name ?? '',
            style: pw.TextStyle(
              font: pw.Font.helveticaBold(),
              fontSize: 13,
              color: PdfColors.black,
            ),
          ),
          if (client.email?.isNotEmpty ?? false)
            pw.Text(
              client.email!,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          if (client.phone?.isNotEmpty ?? false)
            pw.Text(
              client.phone!,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          if (client.address?.isNotEmpty ?? false)
            pw.Text(
              client.address!,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
        ],
      ],
    );
  }

  // ── Items table: accent color ONLY on header row ───────────────────────────
  pw.Widget _buildItemsTable(
    List<dynamic> items,
    PdfColor accentColor,
  ) {
    const rowAlt = PdfColor(0.973, 0.980, 0.988); // very light grey-blue

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5), // Description
        1: pw.FlexColumnWidth(1),   // Qty
        2: pw.FlexColumnWidth(2),   // Unit Price
        3: pw.FlexColumnWidth(2),   // Amount
      },
      children: [
        // ── Header row: accent background, white text ──────────────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _th('DESCRIPTION'),
            _th('QTY', align: pw.Alignment.center),
            _th('UNIT PRICE', align: pw.Alignment.centerRight),
            _th('AMOUNT', align: pw.Alignment.centerRight),
          ],
        ),
        // ── Data rows ──────────────────────────────────────────────────────
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final unitPrice = item.price?.toDouble() ?? 0;
          final qty = item.qty ?? 1;
          final lineTotal = unitPrice * qty;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd ? rowAlt : PdfColors.white,
            ),
            children: [
              _td(item.itemName ?? ''),
              _td(qty.toString(), align: pw.Alignment.center),
              _td(
                '\$${unitPrice.toStringAsFixed(2)}',
                align: pw.Alignment.centerRight,
              ),
              _td(
                '\$${lineTotal.toStringAsFixed(2)}',
                align: pw.Alignment.centerRight,
                bold: true,
              ),
            ],
          );
        }),
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

  pw.Widget _td(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
    bool bold = false,
  }) {
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

  // ── Totals: subtotal → received → balance due ─────────────────────────────
  pw.Widget _buildTotals(double subtotal, double received) {
    final balanceDue = (subtotal - received).clamp(0.0, double.infinity);
    final hasReceived = received > 0;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            _totalRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
            if (hasReceived) ...[
              _totalRow(
                'Received',
                '(\$${received.toStringAsFixed(2)})',
                valueColor: PdfColors.green700,
              ),
            ],
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            ),
            _totalRow(
              hasReceived ? 'BALANCE DUE' : 'TOTAL DUE',
              '\$${(hasReceived ? balanceDue : subtotal).toStringAsFixed(2)}',
              isBold: true,
              fontSize: 13,
            ),
          ],
        ),
      ),
    );
  }

  // ── Notes section ──────────────────────────────────────────────────────────
  pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'NOTES',
          style: pw.TextStyle(
            font: pw.Font.helveticaBold(),
            fontSize: 9,
            color: PdfColors.grey700,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.973, 0.980, 0.988),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Text(
            notes,
            style: pw.TextStyle(
              font: pw.Font.helvetica(),
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
        ),
      ],
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
    final resolvedValueColor = valueColor ?? labelColor;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
              fontSize: fontSize,
              color: labelColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: isBold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
              fontSize: fontSize,
              color: resolvedValueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'TERMS & CONDITIONS',
              style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                fontSize: 8,
                letterSpacing: 1,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Payment is due within 30 days of the invoice date.',
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Authorized Signature',
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Container(
              width: 130,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                ),
              ),
            ),
          ],
        ),
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

  // Single flag used by both buttons to prevent double-taps
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bp = Provider.of<BusinessProvider>(context, listen: false);
      _business = await bp.getString();
      if (mounted) setState(() {});
    });
  }

  // Used by PdfPreview widget for live rendering
  Future<Uint8List> _buildPdf(PdfPageFormat format) =>
      _pdfService.invoicePdfGenerate(
        widget.invoice!,
        widget.provider,
        business: _business,
      );

  /// Generates the PDF, saves it, then opens it with the device's PDF viewer.
  ///
  /// [persist] = true  → saves to the app's documents directory (survives temp
  ///                      cleanup) so the user can find the file later.
  /// [persist] = false → saves to the system temp directory (fast, throwaway).
  ///
  /// OpenFile.open() is used instead of share_plus because the SharePlus
  /// future can hang indefinitely on some Android versions when the user
  /// dismisses the share sheet without selecting a target, leaving the button
  /// stuck in a loading state. The PDF viewer opened by OpenFile always has its
  /// own share button, so the user can still forward the invoice from there.
  Future<void> _openPdf({required bool persist}) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await _pdfService.invoicePdfGenerate(
        widget.invoice!,
        widget.provider,
        business: _business,
      );
      final dir = persist
          ? await getApplicationDocumentsDirectory()
          : await getTemporaryDirectory();
      final invoiceId = widget.invoice?.invoiceId ?? 'draft';
      final file = File('${dir.path}/Invoice_$invoiceId.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (_) {
      // Silently ignore — if OpenFile fails the PDF was still generated
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
          // ── Nav bar ──────────────────────────────────────────────────────
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

          // ── PDF preview ──────────────────────────────────────────────────
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
              previewPageMargin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              padding: EdgeInsets.zero,
              build: _buildPdf,
            ),
          ),

          // ── Bottom action bar ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: kSurface,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                // Download — saves to documents dir so the file persists
                Expanded(
                  child: AppButton(
                    outlined: true,
                    txt: _generating ? 'Saving…' : 'Download',
                    onTap: _generating ? null : () => _openPdf(persist: true),
                  ),
                ),
                const SizedBox(width: 12),
                // Send — opens PDF in viewer; user can share from there
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
