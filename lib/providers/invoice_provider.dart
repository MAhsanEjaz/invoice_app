import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceProvider extends ChangeNotifier {
  List<ItemModel> item = [];

  List<InvoiceModel> invoice = [];
  List<InvoiceModel> paidInvoice = [];
  List<InvoiceModel> unPaidInvoice = [];

  InvoiceProvider() {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    await getSaveInvoices();
    getInvoices();
  }

  int lastId = 0;
  int newItemId = 0;

  deleteExistingItems(int? itemId) {
    for (var l in invoice) {
      l.items!.removeWhere((element) => element.id == itemId);

      print('this Delete Function--->${itemId}');
      notifyListeners();
    }
  }

  addExistingItemWithId(
    ItemModel model,
    List<ItemModel> item,
    String? itemName,
    String? qty,
    String? price,
    String? note,
  ) {
    for (var element in invoice) {
      model = element.items!.firstWhere(
        (element) => element.id == model.id,
        orElse: () => ItemModel(duplicate: false),
      );

      model.itemName = itemName;
      model.qty = int.tryParse(qty!);
      model.price = double.parse(price!);
      model.note = note;
    }

    item.add(
      ItemModel(
        price: model!.price,
        qty: model!.qty,
        note: model!.note,
        itemName: model!.itemName,
        id: model!.id,
        duplicate: true,
      ),
    );

    notifyListeners();
    print('itemDuplicate--->${jsonEncode(item)}');
  }

  addInvoice(InvoiceModel newInvoice) {
    lastId += 1;
    newInvoice.invoiceId = lastId;

    invoice.add(newInvoice);

    print('invoiceJson---->${jsonEncode(invoice)}');
    getInvoices();

    saveInvoice();

    notifyListeners();
  }

  updateInvoiceStatus(String val, int invoiceId) {
    final invoiceIdData = invoice.firstWhere(
      (element) => element.invoiceId == invoiceId,
    );

    invoiceIdData.invoiceStatus = val;

    getInvoices();

    print('json-->${jsonEncode(invoice)}');

    saveInvoice();
    notifyListeners();
  }

  getInvoices() {
    paidInvoice.clear();
    unPaidInvoice.clear();

    for (var l in invoice) {
      if (l.invoiceStatus == 'Paid') {
        paidInvoice.add(l);
      } else {
        unPaidInvoice.add(l);
      }

      notifyListeners();
    }
  }

  itemUpdate(
    int itemId,
    String? itemName,
    String? note,
    double price,
    int qty,
  ) {
    for (var element in invoice) {
      final itemsUpdate = element.items!.firstWhere(
        (element) => element.id == itemId,
        orElse: () => ItemModel(duplicate: false),
      );

      itemsUpdate.itemName = itemName!;
      itemsUpdate.note = note!;
      itemsUpdate.qty = qty!;
      itemsUpdate.price = price!;
    }

    print('this Function');
    saveInvoice();
    notifyListeners();
  }

  updateClient(
    int id,
    String? name,
    String? phone,
    String? email,
    String? address,
  ) {
    for (var l in invoice) {
      final data = l.clients!.firstWhere(
        (element) => element.id == id,
        orElse: () => ClientModel(), // avoid crash
      );

      if (data.id != null) {
        data.name = name;
        data.phone = phone;
        data.email = email;
        data.address = address;
      }
    }

    notifyListeners();
  }

  num myCalPrice = 0;

  getTotalPriceOfItems(int invoiceId) {
    final data = invoice.firstWhere(
      (element) => element.invoiceId == invoiceId,
    );

    final myPrice = data.items!.fold<num>(
      0,
      (pre, newPrice) =>
          double.parse(pre.toString())! +
          double.parse(newPrice.price.toString()) * newPrice.qty!,
    );

    myCalPrice = myPrice;

    notifyListeners();

    print('myPrice--->${myPrice}');
  }

  void addMoreInvoices(int invoiceId, ItemModel? itemModel) {
    final myInvoice = invoice.firstWhere(
      (element) => element.invoiceId == invoiceId,
    );

    print('run new');

    // Step 1: Calculate highest existing ID
    newItemId = 1;
    for (var element in myInvoice.items!) {
      if (element.id != null && element.id! > newItemId) {
        newItemId = element.id!;
      }
      print('existingId --> ${element.id}');
    }

    // Step 2: Assign next ID to new item
    itemModel!.id = newItemId + 1;
    myInvoice.items!.add(itemModel);

    print('addedItemId --> ${itemModel.id}');
    print('itemJson --> ${jsonEncode(invoice)}');

    saveInvoice();
    notifyListeners();
  }

  deleteInvoice(int invoiceId, int itemId) {
    final data = invoice.firstWhere(
      (element) => element.invoiceId == invoiceId,
    );

    data.items!.removeWhere((element) => element.id == itemId);

    saveInvoice();
    notifyListeners();
  }

  saveInvoice() async {
    final prefs = await SharedPreferences.getInstance();

    final data = invoice.map((element) => element.toJson()).toList();

    final myData = data.map((element) => json.encode(element)).toList();

    await prefs.setStringList('invoices', myData);
  }

  getSaveInvoices() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList('invoices');

    if (data != null) {
      invoice =
          data
              .map((element) => InvoiceModel.fromJson(jsonDecode(element)))
              .toList();
    }

    if (invoice.isNotEmpty) {
      for (var l in invoice) {
        lastId = l.invoiceId!;
      }
    }
    print('lastId-->${lastId}');

    print('saveInvoiceList--->${jsonEncode(invoice)}');
    notifyListeners();
  }
}
