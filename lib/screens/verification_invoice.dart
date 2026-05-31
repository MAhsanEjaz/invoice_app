import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/pdf/pdf_service.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/screens/home_screen.dart';
import 'package:invoicemaker/screens/new_invoice_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/pdf_templates_colors_provider.dart';

class VerificationInvoice extends StatefulWidget {
  ClientModel? clientModel;
  ItemModel? itemModel;
  InvoiceModel? invoiceModel;

  VerificationInvoice({
    super.key,
    this.itemModel,
    this.clientModel,
    this.invoiceModel,
  });

  @override
  State<VerificationInvoice> createState() => _VerificationInvoiceState();
}

class _VerificationInvoiceState extends State<VerificationInvoice> {
  bool toggleVal = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((e) {
      final invoice = Provider.of<InvoiceProvider>(context, listen: false);

      invoice.getTotalPriceOfItems(widget.invoiceModel!.invoiceId!);
    });
  }

  int selectColor = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoice, _) {
        if (widget.invoiceModel!.invoiceStatus == 'Paid') {
          toggleVal = true;
        } else {
          toggleVal = false;
        }

        return WillPopScope(
          onWillPop: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false,
            );
            return false;
          },
          child: CupertinoPageScaffold(
            backgroundColor: scaffoldColor,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      customHeight(context, .01),

                      CupertinoNavigationBar(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: buttonColor,

                            // size: responseText(context, 0.06),
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            Navigation.go(
                              context,
                              NewInvoiceScreen(
                                invoiceId: widget.invoiceModel!.invoiceId,
                                invoice: widget.invoiceModel,
                              ),
                            );
                          },
                          child: Icon(
                            CupertinoIcons.pencil_circle_fill,
                            color: buttonColor,
                          ),
                        ),
                      ),

                      preview(invoice),
                    ],
                  ),
                ),

                Consumer<TemplatesColorsProvider>(
                  builder: (context, data, _) {
                    return Container(
                      decoration: BoxDecoration(color: Colors.white),

                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey.shade100,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  onPressed: () {
                                    showCupertinoModalPopup(
                                      context: context,
                                      builder:
                                          (context) => BottomSheet(
                                            onClosing: () {},
                                            builder:
                                                (context) => StatefulBuilder(
                                                  builder: (context, setstate) {
                                                    return Container(
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Wrap(
                                                            children: [
                                                              for (var l
                                                                  in data.colors
                                                                      .asMap()
                                                                      .entries) ...[
                                                                InkWell(
                                                                  child: Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          8.0,
                                                                        ),
                                                                    child: Container(
                                                                      height:
                                                                          50,
                                                                      width: 50,

                                                                      decoration:
                                                                          BoxDecoration(
                                                                            color:
                                                                                l.value,
                                                                          ),
                                                                      child:
                                                                          selectColor ==
                                                                                  l.key
                                                                              ? Icon(
                                                                                Icons.check,
                                                                                color:
                                                                                    Colors.white,
                                                                              )
                                                                              : SizedBox(),
                                                                    ),
                                                                  ),
                                                                  onTap: () {
                                                                    selectColor =
                                                                        l.key;

                                                                    data.selectColor(
                                                                      l.value,
                                                                    );

                                                                    setstate(
                                                                      () {},
                                                                    );
                                                                  },
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                          ),
                                    ).then((e) {
                                      Navigation.go(
                                        context,
                                        PdfInvoiceScreen(
                                          invoice: widget.invoiceModel,
                                          provider: data,
                                        ),
                                      );
                                    });
                                  },
                                  icon: Icon(
                                    CupertinoIcons.eye,
                                    color: Colors.black,
                                  ),
                                  label: Text(
                                    'Preview',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 50,

                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),

                                  onPressed: () async {
                                    final pdfData = await PdfService()
                                        .invoicePdfGenerate(
                                          widget.invoiceModel!,
                                          data,
                                        );

                                    final tempDir =
                                        await getTemporaryDirectory();
                                    final pdfFilePath =
                                        '${tempDir.path}/Ledger.pdf';

                                    final pdfFile = File(pdfFilePath);
                                    await pdfFile.writeAsBytes(pdfData);

                                    await OpenFile.open(pdfFilePath);
                                  },
                                  label: Text(
                                    'Send Invoice',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget preview(InvoiceProvider? invoiceProvider) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),

                  Text(widget.clientModel!.name!),
                  SizedBox(height: 12),
                  Text(invoiceProvider!.myCalPrice.toStringAsFixed(2)),

                  SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color:
                          toggleVal
                              ? Colors.green.shade100
                              : Colors.orangeAccent.shade100,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 7.0,
                        horizontal: 6,
                      ),
                      child: Text(toggleVal ? 'Paid' : 'Not sent'),
                    ),
                  ),
                  SizedBox(height: 5),
                  customDivider(),
                  Material(
                    surfaceTintColor: Colors.white,
                    color: Colors.white,
                    child: Row(
                      children: [
                        Text('Paid', style: TextStyle(fontSize: 16)),
                        Spacer(),
                        Switch(
                          activeColor: buttonColor,

                          value: toggleVal!,
                          onChanged: (val) {
                            toggleVal = val;

                            if (toggleVal!) {
                              print('Paid');

                              invoiceProvider!.updateInvoiceStatus(
                                'Paid',
                                widget.invoiceModel!.invoiceId!,
                              );
                            } else {
                              invoiceProvider!.updateInvoiceStatus(
                                'UnPaid',
                                widget.invoiceModel!.invoiceId!,
                              );
                            }

                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  customDivider(),
                  SizedBox(height: 5),

                  Row(
                    children: [
                      Text('Received'),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('0'),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),
                ],
              ),
            ),
          ),

          SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Text('Issued'),
                Spacer(),
                Text(widget.invoiceModel!.date!),
              ],
            ),
          ),

          SizedBox(height: 19),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Text('invoice #'),
                Spacer(),
                Text('${widget.invoiceModel!.invoiceId}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget customDivider() {
    return Divider(color: Colors.black12);
  }
}
