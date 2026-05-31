import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/items_provider.dart';
import 'package:invoicemaker/screens/verification_invoice.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/client_model.dart';
import '../models/item_model.dart';
import 'add_client_screen.dart';
import 'add_item_screen.dart';
import 'client_view_screen.dart';
import 'items_screen.dart';

class NewInvoiceScreen extends StatefulWidget {
  InvoiceModel? invoice;

  int? invoiceId;

  NewInvoiceScreen({this.invoiceId, this.invoice});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  getInvoiceData() {
    final invoiceProvider = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    );
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);

    if (widget.invoice != null) {
      // set date and last invoice ID
      selectDate = widget.invoice!.date;
      invoiceProvider.lastId = widget.invoice!.invoiceId!;
      print('lastId---->${widget.invoice!.invoiceId!}');
      // add clients to client provider
      for (var client in widget.invoice!.clients!) {
        clientProvider.selectClient(
          client.name,
          client.address,
          client.phone,
          client.email,
          client.id,
        );
      }

      // add items to item provider or local list

      final invoiceId = widget.invoice!.invoiceId;

      // Find the invoice in the provider that matches this ID
      final targetInvoice = invoiceProvider.invoice.firstWhere(
        (inv) => inv.invoiceId == invoiceId,
      );

      if (targetInvoice != null) {
        for (var itemsX in widget.invoice!.items!) {
          // Check if item already exists in the target invoice
          final exists =
              targetInvoice.items?.any((item) => item.id == itemsX.id) ?? false;

          if (!exists) {
            targetInvoice.items ??= []; // Initialize if null
            targetInvoice.items!.add(
              ItemModel(
                id: itemsX.id,
                price: itemsX.price,
                qty: itemsX.qty,
                note: itemsX.note,
                itemName: itemsX.itemName,
                duplicate: false,
              ),
            );
          }
        }
      }
    }
  }

  int invoiceId = 0;

  String? selectDate;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((e) {
      selectDate = customDateFormat(DateTime.now().toString());
      getInvoiceData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ClientProvider, ItemProvider, InvoiceProvider>(
      builder: (context, client, item, invoice, _) {
        print('clients-->${jsonEncode(client.client)}');

        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: Column(
            children: [
              customHeight(context, .01),
              CupertinoNavigationBar(
                leading: closeButton(context, () {
                  client.clearClientFromList();

                  item.item.clear();
                  selectDate = null;

                  invoice.invoice.forEach((element) {
                    invoice.lastId = element.invoiceId!;
                  });
                  setState(() {});
                }),
                middle:
                    item.item.isNotEmpty || widget.invoice != null
                        ? Text(
                          widget.invoice != null
                              ? 'Update Invoice'
                              : 'New Invoice',
                        )
                        : SizedBox(),
              ),
              customHeight(context, .01),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.item.isNotEmpty || widget.invoice != null)
                          SizedBox()
                        else
                          Center(
                            child: Text(
                              'New Invoice',
                              style: TextStyle(
                                fontSize: responseText(context, .06),
                                fontWeight: FontWeight.bold,
                                color: buttonColor,
                              ),
                            ),
                          ),

                        if (item.item.isNotEmpty || widget.invoice != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final date = await customDatePicker(
                                        context,
                                      );

                                      if (date != null) {
                                        print('data-->${date}');

                                        selectDate = customDateFormat(
                                          date.toString(),
                                        );
                                      }

                                      setState(() {});
                                    },
                                    child: headerWidget(
                                      Icons.calendar_month,
                                      selectDate ??
                                          '${customDateFormat(DateTime.now().toString())}',
                                    ),
                                  ),
                                ),

                                SizedBox(width: 10),

                                Expanded(
                                  child: headerWidget(
                                    CupertinoIcons.doc,
                                    '${widget.invoice != null ? invoice.lastId : invoice.lastId + 1}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        customHeight(context, .02),
                        clientCard(client, invoice),
                        customHeight(context, .01),
                        itemCard(item, invoice),
                        customHeight(context, .02),
                        totalPriceCard(item),
                      ],
                    ),
                  ),
                ),
              ),

              if (client.name != null && item.item.isNotEmpty ||
                  widget.invoice != null)
                Container(
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
                              onPressed: () {},
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
                              onPressed:
                                  widget.invoice != null
                                      ? () {}
                                      : () async {
                                        print('duplicate-->${duplicate}');

                                        await invoice.addInvoice(
                                          InvoiceModel(
                                            invoiceStatus: 'UnPaid',
                                            businessName: 'Kaka Business',
                                            date: selectDate,
                                            invoiceId: invoice.lastId,
                                            items:
                                                item.item
                                                    .map(
                                                      (e) => ItemModel(
                                                        itemName: e.itemName,
                                                        note: e.note,
                                                        price: e.price,
                                                        qty: e.qty,
                                                        id: e.id,
                                                        duplicate: e.duplicate
                                                      ),
                                                    )
                                                    .toList(),
                                            clients:
                                                client.client
                                                    .map(
                                                      (e) => ClientModel(
                                                        name: e.name,
                                                        phone: e.phone,
                                                        email: e.email,
                                                        address: e.address,
                                                        id: e.id,
                                                        duplicate: duplicate,
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        );

                                        item.item.clear();
                                        client.client.clear();
                                        client.clearClientFromList();

                                        // Access the latest added invoice based on lastId
                                        final latestInvoice = invoice.invoice
                                            .firstWhere(
                                              (element) =>
                                                  element.invoiceId ==
                                                  invoice.lastId,
                                            );

                                        // Navigate with the corresponding client and item models
                                        Navigation.go(
                                          context,
                                          VerificationInvoice(
                                            clientModel:
                                                latestInvoice.clients!.first,
                                            itemModel:
                                                latestInvoice.items!.first,
                                            invoiceModel: latestInvoice,
                                          ),
                                        );
                                      },
                              label: Text(
                                widget.invoice != null
                                    ? 'Update Invoice'
                                    : 'Create Invoice',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget clientCard(ClientProvider? client, InvoiceProvider invoice) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Client', style: TextStyle(color: Colors.black54)),

          customHeight(context, .02),

          GestureDetector(
            onTap:
                client!.name != null
                    ? () {
                      widget.invoice != null
                          ? null
                          : Navigation.go(
                            context,
                            AddClientScreen(
                              client: client.client,
                              name: client.name,
                              address: client.address,
                              email: client.email,
                              phone: client.phone,
                              id: client.lastId,
                              invoice: invoice.invoice,
                              isPredefined: true,
                            ),
                          );

                      print('clientId-->>${client.lastId}');
                    }
                    : null,

            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 5,
                      ),
                      child:
                          client!.name != null
                              ? SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Icon(
                                      CupertinoIcons.person,
                                      size: 21,
                                      color: buttonColor,
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      client.name.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (invoice.invoice.isNotEmpty) {
                                      Navigation.go(
                                        context,
                                        ClientViewScreen(),
                                      );
                                    } else {
                                      Navigation.go(context, AddClientScreen());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                  ),
                                  label: Text(
                                    'Add Client',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  icon: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7.0,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.person_badge_plus,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget itemCard(ItemProvider item, InvoiceProvider? invoice) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: TextStyle(color: Colors.black54)),

          customHeight(context, .02),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 0),
              child:
                  item.item.isNotEmpty || widget.invoice != null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.invoice != null)
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    CupertinoListTile(
                                      subtitle: Text(
                                        '${widget.invoice!.items![index].qty.toString()} x ${widget.invoice!.items![index].price.toString()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      title: Text(
                                        widget.invoice!.items![index].itemName
                                            .toString(),
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      trailing: Text(
                                        ((widget.invoice!.items![index].price ??
                                                    0) *
                                                (widget
                                                        .invoice!
                                                        .items![index]
                                                        .qty ??
                                                    1))
                                            .toStringAsFixed(2),
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      onTap: () {
                                        print(
                                          'addItemData-->${jsonEncode(widget.invoice)}',
                                        );

                                        Navigation.go(
                                          context,
                                          AddItemScreen(
                                            itemModel:
                                                widget.invoice!.items![index],
                                            isUpdate: true,

                                            invoice: widget.invoice,
                                          ),
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14.0,
                                        vertical: 5,
                                      ),
                                      child: Divider(
                                        height: 0,
                                        color: Colors.black12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              itemCount: widget.invoice!.items!.length,
                              shrinkWrap: true,
                            )
                          else
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    CupertinoListTile(
                                      subtitle: Text(
                                        '${item.item[index].qty.toString()} x ${item.item[index].price.toString()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      title: Text(
                                        item.item[index].itemName.toString(),
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      trailing: Text(
                                        ((item.item[index].price ?? 0) *
                                                (item.item[index].qty ?? 1))
                                            .toStringAsFixed(2),
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      onTap: () {
                                        Navigation.go(
                                          context,
                                          AddItemScreen(
                                            itemModel: item.item[index],
                                          ),
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14.0,
                                        vertical: 5,
                                      ),
                                      child: Divider(
                                        height: 0,
                                        color: Colors.black12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              itemCount: item.item.length,
                              shrinkWrap: true,
                            ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 17.0,
                              horizontal: 10,
                            ),
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (invoice!.invoice.isNotEmpty) {
                                    Navigation.go(context, ItemsScreen());
                                  } else {
                                    Navigation.go(
                                      context,
                                      AddItemScreen(invoice: widget.invoice),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade500,
                                  elevation: 0,
                                ),
                                label: Text(
                                  'Add Item',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7.0,
                                  ),
                                  child: Icon(
                                    Icons.file_open_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 17.0,
                              horizontal: 5,
                            ),
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (invoice!.invoice.isNotEmpty) {
                                    Navigation.go(context, ItemsScreen());
                                  } else {
                                    Navigation.go(
                                      context,
                                      AddItemScreen(invoice: widget.invoice),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                ),
                                label: Text(
                                  'Add Item',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                icon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7.0,
                                  ),
                                  child: Icon(
                                    Icons.file_open_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget totalPriceCard(ItemProvider itemProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: buttonColor,
                ),
              ),
              Spacer(),

              if (widget.invoice != null)
                Text(
                  widget.invoice!.items!
                      .fold<double>(0.0, (sum, item) {
                        final qty = item.qty ?? 0;
                        final price = item.price ?? 0;
                        return sum + (price * qty);
                      })
                      .toStringAsFixed(2),
                )
              else
                Text(
                  itemProvider.item
                      .fold<double>(0.0, (sum, item) {
                        final qty = item.qty ?? 0;
                        final price = item.price ?? 0;
                        return sum + (price * qty);
                      })
                      .toStringAsFixed(2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget headerWidget(IconData? icon, String? title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: buttonColor),
            SizedBox(width: 10),
            Text(title!, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
