import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/models/bank_model.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/services/notification_service.dart';
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
    // Update the item in-place via its existing reference — no cross-invoice loop
    model.itemName = itemName;
    model.qty = int.tryParse(qty ?? '');
    model.price = double.tryParse(price ?? '');
    model.note = note;

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

    saveInvoice();
    notifyListeners();
  }

  Future<void> addInvoice(InvoiceModel newInvoice) async {
    lastId += 1;
    newInvoice.invoiceId = lastId;

    invoice.add(newInvoice);
    getInvoices();

    await saveInvoice();

    notifyListeners();

    final isInvoice = (newInvoice.documentType ?? 'Invoice') == 'Invoice';
    if (isInvoice && newInvoice.dueDate != null && newInvoice.invoiceStatus != 'Paid') {
      final clientName = (newInvoice.clients?.isNotEmpty ?? false)
          ? (newInvoice.clients!.first.name ?? 'Client')
          : 'Client';
      NotificationService.scheduleInvoiceReminder(
        invoiceId: newInvoice.invoiceId!,
        clientName: clientName,
        invoiceNumber: newInvoice.invoiceId.toString(),
        dueDate: newInvoice.dueDate!,
      );
    }
  }

  updateInvoiceStatus(String val, int invoiceId) {
    final inv = invoice.firstWhere(
      (element) => element.invoiceId == invoiceId,
    );

    inv.invoiceStatus = val;

    getInvoices();
    saveInvoice();
    notifyListeners();

    if (val == 'Paid') {
      NotificationService.cancelInvoiceReminder(invoiceId);
    } else if (inv.dueDate != null) {
      final clientName = (inv.clients?.isNotEmpty ?? false)
          ? (inv.clients!.first.name ?? 'Client')
          : 'Client';
      NotificationService.scheduleInvoiceReminder(
        invoiceId: invoiceId,
        clientName: clientName,
        invoiceNumber: invoiceId.toString(),
        dueDate: inv.dueDate!,
      );
    }
  }

  getInvoices() {
    paidInvoice.clear();
    unPaidInvoice.clear();

    for (var l in invoice) {
      // Only actual invoices (not quotes/estimates) go into paid/unpaid lists
      final isInvoice = (l.documentType ?? 'Invoice') == 'Invoice';
      if (!isInvoice) continue;
      if (l.invoiceStatus == 'Paid') {
        paidInvoice.add(l);
      } else {
        unPaidInvoice.add(l);
      }
    }
    notifyListeners();
  }

  itemUpdate(
    int itemId,
    String? itemName,
    String? note,
    double price,
    int qty, {
    int? invoiceId,
  }) {
    // When invoiceId is provided, only touch that invoice; otherwise fall back
    // to updating the first invoice that contains the item (legacy behaviour).
    final targets = invoiceId != null
        ? invoice.where((e) => e.invoiceId == invoiceId)
        : invoice;

    for (final element in targets) {
      if (element.items == null) continue;
      final idx = element.items!.indexWhere((e) => e.id == itemId);
      if (idx < 0) continue;
      element.items![idx].itemName = itemName ?? '';
      element.items![idx].note = note ?? '';
      element.items![idx].qty = qty;
      element.items![idx].price = price;
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

    saveInvoice();
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
          pre.toDouble() +
          (newPrice.price?.toDouble() ?? 0.0) * (newPrice.qty ?? 1),
    );

    myCalPrice = myPrice;
    notifyListeners();
  }

  void addMoreInvoices(int invoiceId, ItemModel? itemModel) {
    final myInvoice = invoice.firstWhere(
      (element) => element.invoiceId == invoiceId,
    );

    myInvoice.items ??= [];

    // Find the highest existing item ID in this invoice, starting from 0
    int maxId = 0;
    for (var element in myInvoice.items!) {
      if (element.id != null && element.id! > maxId) {
        maxId = element.id!;
      }
    }

    itemModel!.id = maxId + 1;
    newItemId = itemModel.id!; // keep field in sync for external readers
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

  /// Updates the mutable fields of an invoice (date, dueDate, notes, termsConditions, bank).
  void updateInvoiceDetails(
    int invoiceId, {
    String? date,
    String? dueDate,
    String? notes,
    String? termsConditions,
    BankModel? bank,
  }) {
    final inv = invoice.firstWhere((e) => e.invoiceId == invoiceId);
    if (date != null) inv.date = date;
    inv.dueDate = dueDate;
    inv.notes = notes;
    inv.termsConditions = termsConditions;
    inv.bank = bank;
    saveInvoice();
    notifyListeners();

    final isInvoice = (inv.documentType ?? 'Invoice') == 'Invoice';
    if (isInvoice && inv.invoiceStatus != 'Paid') {
      if (dueDate != null) {
        final clientName = (inv.clients?.isNotEmpty ?? false)
            ? (inv.clients!.first.name ?? 'Client')
            : 'Client';
        NotificationService.scheduleInvoiceReminder(
          invoiceId: invoiceId,
          clientName: clientName,
          invoiceNumber: invoiceId.toString(),
          dueDate: dueDate,
        );
      } else {
        NotificationService.cancelInvoiceReminder(invoiceId);
      }
    }
  }

  /// Persists the amount received against an invoice.
  void updateReceivedAmount(int invoiceId, double amount) {
    final inv = invoice.firstWhere((e) => e.invoiceId == invoiceId);
    inv.receivedAmount = amount;
    saveInvoice();
    notifyListeners();
  }

  /// Updates the bank account linked to an invoice.
  void updateInvoiceBank(int invoiceId, BankModel? bank) {
    final inv = invoice.firstWhere((e) => e.invoiceId == invoiceId);
    inv.bank = bank;
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
    NotificationService.cancelInvoiceReminder(invoiceId);
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
      lastId = invoice
          .map((l) => l.invoiceId ?? 0)
          .reduce((a, b) => a > b ? a : b);
    }
    notifyListeners();
  }
}
