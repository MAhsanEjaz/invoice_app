import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/screens/setting_page.dart';
import 'package:invoicemaker/screens/verification_invoice.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';

import 'new_invoice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<int, Widget> children = {
    0: Text('Unpaid', style: TextStyle(color: buttonColor)),
    1: Text('Paid', style: TextStyle(color: buttonColor)),
  };

  int groupVal = 0;

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoice, _) {
        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        CupertinoNavigationBar(
                          leading: Icon(
                            CupertinoIcons.chat_bubble,
                            color: buttonColor,
                            size: responseText(context, 0.06),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              Navigation.go(context, SettingPage());
                            },
                            child: Icon(
                              CupertinoIcons.settings,
                              color: buttonColor,
                              size: responseText(context, 0.06),
                            ),
                          ),
                        ),

                        customHeight(context, .02),
                        Text(
                          'Invoices',
                          style: TextStyle(
                            color: buttonColor,
                            fontSize: responseText(context, 0.063),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        customHeight(context, .01),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: CupertinoSlidingSegmentedControl(
                              children: children,
                              onValueChanged: (val) {
                                groupVal = val!;
                                setState(() {});
                              },
                              groupValue: groupVal,
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    invoice.invoice.isNotEmpty
                                        ? Colors.transparent
                                        : Colors.black12,
                              ),
                              borderRadius: BorderRadius.circular(0),
                            ),
                            height: MediaQuery.sizeOf(context).height * .60,
                            width: double.infinity,
                            child:
                                invoice.invoice.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.doc,
                                            size: 40,
                                            color: buttonColor.withOpacity(.6),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Start by creating invoice',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          if (groupVal == 0)
                                            for (
                                              int k = 0;
                                              k < invoice.unPaidInvoice.length;
                                              k++
                                            ) ...[
                                              for (
                                                int i = 0;
                                                i <
                                                    invoice
                                                        .unPaidInvoice[k]
                                                        .clients!
                                                        .length;
                                                i++
                                              ) ...[
                                                ClipRRect(
                                                  borderRadius: BorderRadius.only(
                                                    topRight: Radius.circular(
                                                      k == 0 ? 10 : 0,
                                                    ),
                                                    topLeft: Radius.circular(
                                                      k == 0 ? 10 : 0,
                                                    ),
                                                    bottomRight: Radius.circular(
                                                      k ==
                                                              invoice
                                                                      .unPaidInvoice
                                                                      .length -
                                                                  1
                                                          ? 10
                                                          : 0,
                                                    ),
                                                    bottomLeft: Radius.circular(
                                                      k ==
                                                              invoice
                                                                      .unPaidInvoice
                                                                      .length -
                                                                  1
                                                          ? 10
                                                          : 0,
                                                    ),
                                                  ),
                                                  child: CupertinoListTile(
                                                    onTap: () {
                                                      final latestInvoice = invoice
                                                          .invoice
                                                          .firstWhere(
                                                            (element) =>
                                                                element
                                                                    .invoiceId ==
                                                                invoice
                                                                    .unPaidInvoice[k]
                                                                    .invoiceId,
                                                          );

                                                      print(
                                                        'invoiceNum-->${latestInvoice.invoiceId}',
                                                      );

                                                      Navigation.go(
                                                        context,
                                                        VerificationInvoice(
                                                          invoiceModel:
                                                              latestInvoice,
                                                          clientModel:
                                                              latestInvoice
                                                                  .clients!
                                                                  .first,
                                                          itemModel:
                                                              latestInvoice
                                                                  .items!
                                                                  .first,
                                                        ),
                                                      );
                                                    },
                                                    backgroundColor:
                                                        Colors.white,
                                                    title: Text(
                                                      invoice
                                                          .unPaidInvoice[k]
                                                          .clients![i]
                                                          .name
                                                          .toString(),
                                                    ),
                                                    subtitle: Text(
                                                      invoice
                                                          .unPaidInvoice[i]
                                                          .date
                                                          .toString(),
                                                    ),
                                                    trailing: Text(
                                                      invoice
                                                          .unPaidInvoice[k]
                                                          .items!
                                                          .fold<double>(
                                                            0.0,
                                                            (sum, item) =>
                                                                sum +
                                                                (item.price! *
                                                                            item.qty! ??
                                                                        0)
                                                                    .toDouble(),
                                                          )
                                                          .toStringAsFixed(
                                                            2,
                                                          ), // optional: formats to 2 decimal places
                                                    ),
                                                  ),
                                                ),

                                                Divider(
                                                  height: 0,
                                                  color: scaffoldColor,
                                                ),
                                              ],
                                            ]
                                          else ...[
                                            for (
                                              int k = 0;
                                              k < invoice.paidInvoice.length;
                                              k++
                                            ) ...[
                                              for (
                                                int i = 0;
                                                i <
                                                    invoice
                                                        .paidInvoice[k]
                                                        .clients!
                                                        .length;
                                                i++
                                              ) ...[
                                                ClipRRect(
                                                  borderRadius: BorderRadius.only(
                                                    topRight: Radius.circular(
                                                      k == 0 ? 10 : 0,
                                                    ),
                                                    topLeft: Radius.circular(
                                                      k == 0 ? 10 : 0,
                                                    ),
                                                    bottomRight: Radius.circular(
                                                      k ==
                                                              invoice
                                                                      .paidInvoice
                                                                      .length -
                                                                  1
                                                          ? 10
                                                          : 0,
                                                    ),
                                                    bottomLeft: Radius.circular(
                                                      k ==
                                                              invoice
                                                                      .paidInvoice
                                                                      .length -
                                                                  1
                                                          ? 10
                                                          : 0,
                                                    ),
                                                  ),
                                                  child: CupertinoListTile(
                                                    onTap: () {
                                                      final latestInvoice = invoice
                                                          .invoice
                                                          .firstWhere(
                                                            (element) =>
                                                                element
                                                                    .invoiceId ==
                                                                invoice
                                                                    .paidInvoice[k]
                                                                    .invoiceId,
                                                          );

                                                      Navigation.go(
                                                        context,
                                                        VerificationInvoice(
                                                          itemModel:
                                                              latestInvoice
                                                                  .items!
                                                                  .first,
                                                          clientModel:
                                                              latestInvoice
                                                                  .clients!
                                                                  .first,
                                                          invoiceModel:
                                                              latestInvoice,
                                                        ),
                                                      );
                                                    },
                                                    backgroundColor:
                                                        Colors.white,
                                                    title: Text(
                                                      invoice
                                                          .paidInvoice[k]
                                                          .clients![i]
                                                          .name
                                                          .toString(),
                                                    ),
                                                    subtitle: Text(
                                                      invoice
                                                          .paidInvoice[i]
                                                          .date
                                                          .toString(),
                                                    ),
                                                    trailing: Text(
                                                      invoice
                                                          .paidInvoice[k]
                                                          .items!
                                                          .fold<double>(
                                                            0.0,
                                                            (sum, item) =>
                                                                sum +
                                                                (item.price! *
                                                                            item.qty! ??
                                                                        0)
                                                                    .toDouble(),
                                                          )
                                                          .toStringAsFixed(
                                                            2,
                                                          ), // optional: formats to 2 decimal places
                                                    ),
                                                  ),
                                                ),

                                                Divider(
                                                  height: 0,
                                                  color: scaffoldColor,
                                                ),
                                              ],
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                          ),
                        ),

                        SizedBox(height: 2),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 10,
                    ),
                    child: AppButton(
                      onTap: () {
                        Navigation.go(context, NewInvoiceScreen());
                      },
                      txt: 'Create Invoice',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
