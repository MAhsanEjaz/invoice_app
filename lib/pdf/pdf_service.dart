import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfService {
  Future<Uint8List> invoicePdfGenerate(
    InvoiceModel invoice,
    TemplatesColorsProvider? provider,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (context) {
          return [
            // Header section
            pw.Container(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Colored Section
                  pw.Container(
                    width: 200,
                    padding: pw.EdgeInsets.all(8),
                    color: PdfColor.fromInt(
                      int.parse(provider!.colorCode!, radix: 16),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 20),
                        pw.Text(
                          'FROM',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text('Your Name'),
                        pw.Text('Your Address'),
                        pw.Text('City, State, ZIP'),
                        pw.Text('email@example.com'),
                        pw.Text('+123456789'),
                      ],
                    ),
                  ),
                  pw.Spacer(),
                  // Invoice Info
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INVOICE # ${invoice.invoiceId}'),
                        pw.Text('DATE: ${invoice.date}'),
                        pw.Text('DUE DATE: ${invoice.date}'),
                        pw.SizedBox(height: 20),
                        pw.Text(
                          'BILL TO:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(invoice.clients![0].name ?? ''),
                        pw.Text(invoice.clients![0].address ?? ''),
                        pw.Text(invoice.clients![0].email ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Table
            pw.Table.fromTextArray(
              headers: [
                'Description',
                'QTY',
                'Price',
                'Discount',
                'Tax',
                'Amount',
              ],
              data:
                  invoice.items!.map((item) {
                    final total =
                        (double.parse(item.price.toString()) * item.qty!);
                    final tax = total * 0.05;
                    final discount = total * 0.1;
                    final amount = total + tax - discount;

                    return [
                      item.itemName ?? '',
                      item.qty.toString(),
                      item.price.toString(),
                      (discount.toStringAsFixed(2)),
                      (tax.toStringAsFixed(2)),
                      (amount.toStringAsFixed(2)),
                    ];
                  }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            ),

            pw.SizedBox(height: 20),

            // Total Section
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [pw.Text('Subtotal:'), pw.Text('111')],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [pw.Text('Discount:'), pw.Text('111')],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [pw.Text('Tax (5%):'), pw.Text('11')],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [pw.Text('Shipping:'), pw.Text('1')],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '11',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            pw.SizedBox(height: 30),

            // Footer with Terms & Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TERMS & CONDITIONS',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('This payment is due within 7 days.'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Authorized Sign',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      '_________________',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}

class PdfInvoiceScreen extends StatefulWidget {
  InvoiceModel? invoice;

  TemplatesColorsProvider? provider;

  PdfInvoiceScreen({super.key, this.invoice, this.provider});

  @override
  State<PdfInvoiceScreen> createState() => _PdfInvoiceScreenState();
}

class _PdfInvoiceScreenState extends State<PdfInvoiceScreen> {
  final PdfService pdfService = PdfService();

  Uint8List? pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final bytes = await pdfService.invoicePdfGenerate(
      widget.invoice!,
      widget.provider,
    );
    setState(() {
      pdfBytes = bytes;
    });
  }

  Future<void> _sharePdf() async {
    if (pdfBytes == null) return;

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/invoice.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes!);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Here is your invoice PDF.');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CupertinoNavigationBar(leading: closeButton(context)),

          PdfPreview(
            shouldRepaint: true,
            scrollViewDecoration: BoxDecoration(
              color: Colors.grey.withOpacity(.1),
            ),
            // pdfPreviewPageDecoration: BoxDecoration(color: Colors.white),
            dynamicLayout: true,
            actionBarTheme: PdfActionBarTheme(backgroundColor: buttonColor),
            build:
                (format) => pdfService.invoicePdfGenerate(
                  widget.invoice!,
                  widget.provider,
                ),

            canChangePageFormat: false,
            onZoomChanged: (v) {},
            canChangeOrientation: false,
            previewPageMargin: EdgeInsets.all(5),
            padding: EdgeInsets.all(5),
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
            enableScrollToPage: true,
            canDebug: false,
          ),

          Positioned(
            bottom: 14,
            left: 14,
            right: 20,
            child: AppButton(
              onTap: () {
                _sharePdf();
              },
              txt: 'Send Invoice',
            ),
          ),
        ],
      ),
    );
  }
}
