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
        price: model.price,
        qty: model.qty,
        note: model.note,
        itemName: model.itemName,
        id: model.id,
        duplicate: true,
      ),
    );

    notifyListeners();
  }

  addInvoice(InvoiceModel newInvoice) {
    lastId += 1;
    newInvoice.invoiceId = lastId;

    invoice.add(newInvoice);
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
      itemsUpdate.qty = qty;
      itemsUpdate.price = price;
    }

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
          double.parse(pre.toString()) +
          double.parse(newPrice.price.toString()) * newPrice.qty!,
    );

    myCalPrice = myPrice;
    notifyListeners();
  }

  void addMoreInvoices(int invoiceId, ItemModel? itemModel) {
    final myInvoice = invoice.firstWhere(
      (element) => element.invoiceId == invoiceId,
    );

    // Step 1: Calculate highest existing ID
    newItemId = 1;
    for (var element in myInvoice.items!) {
      if (element.id != null && element.id! > newItemId) {
        newItemId = element.id!;
      }
    }

    // Step 2: Assign next ID to new item
    itemModel!.id = newItemId + 1;
    myInvoice.items!.add(itemModel);

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

  /// Updates the mutable fields of an invoice (date, dueDate, notes, termsConditions).
  void updateInvoiceDetails(
    int invoiceId, {
    String? date,
    String? dueDate,
    String? notes,
    String? termsConditions,
  }) {
    final inv = invoice.firstWhere((e) => e.invoiceId == invoiceId);
    if (date != null) inv.date = date;
    inv.dueDate = dueDate;
    inv.notes = notes;
    inv.termsConditions = termsConditions;
    saveInvoice();
    notifyListeners();
  }

  /// Persists the amount received against an invoice.
  void updateReceivedAmount(int invoiceId, double amount) {
    final inv = invoice.firstWhere((e) => e.invoiceId == invoiceId);
    inv.receivedAmount = amount;
    saveInvoice();
    notifyListeners();
  }

  /// Persists the discount applied to an invoice.
  void updateDiscount(int invoiceId, double amount) {
    final inv = invoice.firstWhere((e) => e.invoiceId == invoiceId);
    inv.discount = amount > 0 ? amount : null;
    saveInvoice();
    notifyListeners();
  }

  /// Permanently removes an entire invoice.
  void deleteWholeInvoice(int invoiceId) {
    invoice.removeWhere((e) => e.invoiceId == invoiceId);
    getInvoices();
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
    notifyListeners();
  }
}
