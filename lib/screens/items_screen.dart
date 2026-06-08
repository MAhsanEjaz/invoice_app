import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/screens/add_item_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  getItemsInstance() {
    final provider = Provider.of<InvoiceProvider>(context, listen: false);

    print('jsonItem--->${jsonEncode(provider.invoice)}');
  }

  ItemModel? data;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getItemsInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, invoice, _) {
        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoNavigationBar(
                    padding: EdgeInsetsDirectional.zero,
                    leading: closeButton(context),
                    middle: Text(context.tr('items'),  style: TextStyle(
                      color: buttonColor,
                      fontSize: responseText(context, .05),
                      fontWeight: FontWeight.bold,
                    ),),

                    trailing: Material(
                      color: scaffoldColor,
                      child: InkWell(
                        onTap: () {
                          Navigation.go(
                            context,
                            AddItemScreen(duplicate: false),
                          );
                        },
                        child: Icon(
                          CupertinoIcons.add_circled_solid,
                          color: buttonColor,
                        ),
                      ),
                    ),
                  ),

                  customHeight(context, 0.02),
                  CupertinoTextField(placeholder: context.tr('search_items')),

                  customHeight(context, 0.02),
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Column(
                      children: [
                        for (var l in invoice.invoice) ...[
                          for (var items in l.items!) ...[
                            items.duplicate == true
                                ? SizedBox.shrink()
                                : CupertinoListTile(
                                  additionalInfo: Text(items.price.toString()),
                                  onTap: () {
                                    print(
                                      'itemId--->${jsonEncode(invoice.invoice)}',
                                    );
                                    Navigation.go(
                                      context,
                                      AddItemScreen(
                                        itemModel: items,
                                        duplicate: true,
                                      ),
                                    );
                                  },
                                  title: Text(items.itemName.toString()),
                                ),
                          ],
                        ],
                      ],
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
