import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/items_provider.dart';
import 'package:provider/provider.dart';

import '../models/invoice_model.dart';
import '../services/navigations.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_filed.dart';

class AddItemScreen extends StatefulWidget {
  ItemModel? itemModel;

  bool? isUpdate;

  bool duplicate;

  InvoiceModel? invoice;

  AddItemScreen({
    super.key,
    this.itemModel,
    this.invoice,
    this.isUpdate = false,
    this.duplicate = false,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  initializeItemData() {
    print('invoiceId--->${widget.invoice?.invoiceId}');
    print('itemId--->${widget.itemModel?.id}');

    if (widget.itemModel != null) {
      itemCont.text = widget.itemModel!.itemName!;
      noteCont.text = widget.itemModel!.note!;
      priceCont.text = widget.itemModel!.price.toString();
      qtyCont.text = widget.itemModel!.qty.toString();
    }

    setState(() {});
  }

  TextEditingController itemCont = TextEditingController();
  TextEditingController noteCont = TextEditingController();
  TextEditingController priceCont = TextEditingController();
  TextEditingController qtyCont = TextEditingController();

  initializeAmountAndQty() {
    priceCont.text = '1';
    qtyCont.text = '1';
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeItemData();

    initializeAmountAndQty();

    print('invoiceId--->${widget.invoice?.invoiceId}');
  }

  ItemModel? data;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ItemProvider, InvoiceProvider>(
      builder: (context, item, invoice, _) {
        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: CupertinoNavigationBar(
                  leading: closeButton(context),
                  middle: Text(
                    'New Item',
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: responseText(context, .05),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      addItemsCard(),

                      if (widget.itemModel != null)
                        deleteContact(item, widget.itemModel!.id ?? 0, invoice),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AppButton(
                    onTap: () {
                      if (widget.duplicate == true &&
                          widget.itemModel != null) {
                        invoice.addExistingItemWithId(
                          widget.itemModel!,
                          item.item,
                          itemCont.text.trim(),
                          qtyCont.text,
                          priceCont.text,
                          noteCont.text.trim(),
                        );
                      }

                      if (widget.itemModel != null &&
                          widget.duplicate == false) {
                        item.updateItems(
                          itemCont.text,
                          priceCont.text,
                          qtyCont.text,
                          noteCont.text,
                          widget.itemModel,
                        );
                      } else {
                        if (widget.invoice == null &&
                            widget.duplicate == false) {
                          item.addItems(
                            ItemModel(
                              note: noteCont.text.trim(),
                              id: item.lastId,
                              qty: int.tryParse(qtyCont.text),
                              price: double.tryParse(priceCont.text),
                              itemName: itemCont.text,
                              duplicate: false,
                            ),
                          );
                        } else {
                          if (widget.duplicate == false) {
                            invoice.addMoreInvoices(
                              widget.invoice!.invoiceId!,
                              ItemModel(
                                id: invoice.newItemId,
                                note: noteCont.text.trim(),
                                qty: int.tryParse(qtyCont.text),
                                price: double.tryParse(priceCont.text),
                                itemName: itemCont.text,
                                duplicate: false,
                              ),
                            );
                          }
                        }
                      }

                      print('itemId-->${widget.itemModel?.id!}');

                      if (widget.itemModel?.id != null &&
                          widget.duplicate == false) {
                        invoice.itemUpdate(
                          widget.itemModel!.id!,
                          itemCont.text,
                          noteCont.text,
                          double.parse(priceCont.text.toString()),
                          int.parse(qtyCont.text),
                        );
                      }
                      if (invoice.invoice.isNotEmpty) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                      }

                      setState(() {});
                    },
                    txt:
                        (widget.itemModel != null && widget.duplicate == false)
                            ? 'Update Item'
                            : 'Save Item',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget deleteContact(ItemProvider item, int id, InvoiceProvider? invoice) {
    return GestureDetector(
      onTap: () {
        if (widget.duplicate == true) {
          customCupertinoDialog(context, () {
            invoice!.deleteExistingItems(widget.itemModel!.id);
          });
        } else {
          customCupertinoDialog(context, () async {
            if (widget.isUpdate == true &&
                widget.invoice != null &&
                widget.itemModel?.id != null) {
              await invoice!.deleteInvoice(
                widget.invoice!.invoiceId!,
                widget.itemModel!.id!,
              );
            } else if (widget.itemModel != null) {
              await item.deleteItems(widget.itemModel!, id);
            }

            Navigator.pop(context);
          });
        }
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.delete_solid, color: Colors.red, size: 16),
                SizedBox(width: 10),
                Text(
                  'Delete from invoice',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget addItemsCard() {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextFiled(
                  controller: itemCont,
                  placeholder: 'Item or service provider',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Divider(height: 0, color: Colors.black12),
                ),
                AppTextFiled(
                  controller: noteCont,
                  placeholder: 'Notes (optional)',
                ),
              ],
            ),
          ),

          customHeight(context, 0.04),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                AppTextFiled(
                  controller: priceCont,
                  placeholder: 'Price',
                  textInputType: TextInputType.number,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Divider(height: 0, color: Colors.black12),
                ),
                AppTextFiled(
                  controller: qtyCont,
                  placeholder: 'Quantity',
                  textInputType: TextInputType.number,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
