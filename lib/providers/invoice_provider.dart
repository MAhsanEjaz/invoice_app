import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
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
    await _checkAndCreateRecurringInvoices();
  }

  // ── Recurring helpers ────────────────────────────────────────────────────────

  String _todayIso() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Advances [fromIso] by one interval and keeps advancing until the result
  /// is strictly after [todayIso]. This ensures we never land on a past date.
  String _computeNextFutureDate(String fromIso, String interval, int? customDays, String todayIso) {
    var next = fromIso;
    do {
      next = _computeNextDate(next, interval, customDays);
    } while (next.compareTo(todayIso) <= 0);
    return next;
  }

  String? _toIsoDate(String dateStr) {
    final formats = ['MMM dd, yyyy', 'dd MMM yyyy', 'yyyy-MM-dd', 'dd/MM/yyyy'];
    for (final fmt in formats) {
      final parsed = DateFormat(fmt).tryParse(dateStr);
      if (parsed != null) {
        return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }

  String _computeNextDate(String fromIso, String interval, int? customDays) {
    final from = DateTime.parse(fromIso);
    final DateTime next;
    switch (interval) {
      case 'weekly':
        next = from.add(const Duration(days: 7));
      case 'custom':
        // Clamp to ≥1 to prevent an infinite loop in _computeNextFutureDate
        // when the caller passes 0 or null.
        next = from.add(Duration(days: (customDays ?? 30).clamp(1, 3650)));
      default: // monthly — clamp day to last day of target month to avoid overflow
        final nextYear = from.month == 12 ? from.year + 1 : from.year;
        final nextMonth = from.month == 12 ? 1 : from.month + 1;
        final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        next = DateTime(nextYear, nextMonth, from.day.clamp(1, lastDay));
    }
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }

  Future<void> _checkAndCreateRecurringInvoices() async {
    final todayIso = _todayIso();

    // Guard: run at most once per calendar day so multiple cold-starts or
    // provider re-inits on the same day cannot create duplicate invoices.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('_recurringCheckDate') == todayIso) return;

    final today = DateTime.now();

    final toProcess = invoice
        .where((inv) =>
            inv.isRecurring == true &&
            inv.nextRecurringDate != null &&
            inv.nextRecurringDate!.compareTo(todayIso) <= 0)
        .toList();

    for (final parent in toProcess) {
      // Compute new due date preserving the same offset from invoice date
      String? newDueDateFormatted;
      if (parent.dueDate != null && parent.date != null) {
        final parentDateIso = _toIsoDate(parent.date!);
        final parentDueIso = _toIsoDate(parent.dueDate!);
        if (parentDateIso != null && parentDueIso != null) {
          try {
            final diff = DateTime.parse(parentDueIso).difference(DateTime.parse(parentDateIso)).inDays;
            final newDue = today.add(Duration(days: diff));
            newDueDateFormatted = DateFormat('MMM dd, yyyy').format(newDue);
          } catch (_) {
            newDueDateFormatted = null;
          }
        }
      }

      final newInvoice = InvoiceModel(
        documentType: 'Invoice',
        invoiceStatus: 'UnPaid',
        businessId: parent.businessId,
        businessName: parent.businessName,
        date: DateFormat('MMM dd, yyyy').format(today),
        dueDate: newDueDateFormatted,
        notes: parent.notes,
        termsConditions: parent.termsConditions,
        bank: parent.bank != null
            ? BankModel(
                id: parent.bank!.id,
                accountNumber: parent.bank!.accountNumber,
                title: parent.bank!.title,
                bankName: parent.bank!.bankName,
              )
            : null,
        discount: parent.discount,
        taxRate: parent.taxRate,
        taxLabel: parent.taxLabel,
        items: parent.items
            ?.map((e) => ItemModel(id: e.id, itemName: e.itemName, note: e.note, price: e.price, qty: e.qty, duplicate: false, discount: e.discount, discountType: e.discountType))
            .toList(),
        clients: parent.clients
            ?.map((e) => ClientModel(id: e.id, name: e.name, phone: e.phone, email: e.email, address: e.address, duplicate: false))
            .toList(),
      );

      lastId += 1;
      newInvoice.invoiceId = lastId;
      invoice.add(newInvoice);

      // Advance nextRecurringDate past today (not just one period) so that
      // re-launching the app on the same day never creates a second invoice,
      // even if multiple periods were missed while the app was unused.
      parent.nextRecurringDate = _computeNextFutureDate(
        parent.nextRecurringDate!,
        parent.recurringInterval ?? 'monthly',
        parent.recurringCustomDays,
        todayIso,
      );

      final clientName = (newInvoice.clients?.isNotEmpty ?? false) ? (newInvoice.clients!.first.name ?? 'Client') : 'Client';
      final invNumber = newInvoice.invoiceId.toString();

      await NotificationService.showRecurringInvoiceCreated(
        newInvoiceId: newInvoice.invoiceId!,
        clientName: clientName,
        invoiceNumber: invNumber,
      );

      if (newInvoice.dueDate != null) {
        await NotificationService.scheduleInvoiceReminder(
          invoiceId: newInvoice.invoiceId!,
          clientName: clientName,
          invoiceNumber: invNumber,
          dueDate: newInvoice.dueDate!,
        );
      }
    }

    if (toProcess.isNotEmpty) {
      getInvoices();
      await saveInvoice();
      notifyListeners();
    }

    // Mark today as checked regardless of whether invoices were created.
    await prefs.setString('_recurringCheckDate', todayIso);
  }

  Future<void> updateRecurringSettings(
    int invoiceId, {
    required bool isRecurring,
    String? interval,
    int? customDays,
  }) async {
    final inv = invoice.firstWhere(
      (e) => e.invoiceId == invoiceId,
      orElse: () => throw StateError('Invoice $invoiceId not found'),
    );
    if (isRecurring) {
      inv.isRecurring = true;
      inv.recurringInterval = interval ?? 'monthly';
      inv.recurringCustomDays = interval == 'custom' ? customDays : null;
      if (inv.date != null) {
        final isoDate = _toIsoDate(inv.date!);
        if (isoDate != null) {
          // Advance from the invoice date until strictly after today so that
          // old invoices don't get a past nextRecurringDate and immediately
          // trigger creation on the next launch.
          inv.nextRecurringDate = _computeNextFutureDate(
            isoDate, inv.recurringInterval!, inv.recurringCustomDays, _todayIso());
        }
      }
    } else {
      inv.isRecurring = null;
      inv.recurringInterval = null;
      inv.recurringCustomDays = null;
      inv.nextRecurringDate = null;
    }
    await saveInvoice();
    notifyListeners();
  }

  int lastId = 0;
  int newItemId = 0;

  deleteExistingItems(int? itemId) {
    for (var l in invoice) {
      l.items?.removeWhere((element) => element.id == itemId);
    }
    notifyListeners();
  }

  addExistingItemWithId(
    ItemModel model,
    List<ItemModel> item,
    String? itemName,
    String? qty,
    String? price,
    String? note, {
    double? discount,
    String? discountType,
  }) {
    // Update the item in-place via its existing reference — no cross-invoice loop
    model.itemName = itemName;
    model.qty = int.tryParse(qty ?? '');
    model.price = double.tryParse(price ?? '');
    model.note = note;
    model.discount = (discount != null && discount > 0) ? discount : null;
    model.discountType = (discount != null && discount > 0) ? discountType : null;

    item.add(
      ItemModel(
        price: model.price,
        qty: model.qty,
        note: model.note,
        itemName: model.itemName,
        id: model.id,
        duplicate: true,
        discount: model.discount,
        discountType: model.discountType,
      ),
    );

    saveInvoice();
    notifyListeners();
  }

  Future<void> addInvoice(
    InvoiceModel newInvoice, {
    String Function(int)? numberFormatter,
  }) async {
    lastId += 1;
    newInvoice.invoiceId = lastId;
    if (numberFormatter != null) {
      newInvoice.invoiceNumber = numberFormatter(lastId);
    }

    // Set nextRecurringDate before persisting so listeners see the complete state.
    // Advance past today in case the invoice was created with a backdated date.
    if (newInvoice.isRecurring == true && newInvoice.nextRecurringDate == null && newInvoice.date != null) {
      final isoDate = _toIsoDate(newInvoice.date!);
      if (isoDate != null) {
        newInvoice.nextRecurringDate = _computeNextFutureDate(
          isoDate,
          newInvoice.recurringInterval ?? 'monthly',
          newInvoice.recurringCustomDays,
          _todayIso(),
        );
      }
    }

    invoice.add(newInvoice);
    getInvoices();
    await saveInvoice();
    notifyListeners();

    final isInvoice = (newInvoice.documentType ?? 'Invoice') == 'Invoice';
    if (isInvoice && newInvoice.dueDate != null && newInvoice.invoiceStatus != 'Paid') {
      final clientName = (newInvoice.clients?.isNotEmpty ?? false)
          ? (newInvoice.clients!.first.name ?? 'Client')
          : 'Client';
      await NotificationService.scheduleInvoiceReminder(
        invoiceId: newInvoice.invoiceId!,
        clientName: clientName,
        invoiceNumber: newInvoice.invoiceNumber ?? newInvoice.invoiceId.toString(),
        dueDate: newInvoice.dueDate!,
      );
    }
  }

  /// Creates a new Invoice document from a Quote or Estimate, preserving all items,
  /// client, and financial settings from the source document.
  /// The source Quote/Estimate is removed after conversion so it cannot be
  /// converted a second time and does not clutter the list.
  Future<InvoiceModel> convertToInvoice(
    InvoiceModel source, {
    String Function(int)? numberFormatter,
  }) async {
    final newInvoice = InvoiceModel(
      documentType: 'Invoice',
      invoiceStatus: 'UnPaid',
      businessId: source.businessId,
      businessName: source.businessName,
      date: source.date,
      dueDate: source.dueDate,
      notes: source.notes,
      termsConditions: source.termsConditions,
      bank: source.bank != null
          ? BankModel(
              id: source.bank!.id,
              accountNumber: source.bank!.accountNumber,
              title: source.bank!.title,
              bankName: source.bank!.bankName,
            )
          : null,
      discount: source.discount,
      taxRate: source.taxRate,
      taxLabel: source.taxLabel,
      items: source.items
          ?.map((e) => ItemModel(
                id: e.id,
                itemName: e.itemName,
                note: e.note,
                price: e.price,
                qty: e.qty,
                duplicate: false,
                discount: e.discount,
                discountType: e.discountType,
              ))
          .toList(),
      clients: source.clients
          ?.map((e) => ClientModel(
                id: e.id,
                name: e.name,
                phone: e.phone,
                email: e.email,
                address: e.address,
                duplicate: false,
              ))
          .toList(),
    );
    await addInvoice(newInvoice, numberFormatter: numberFormatter);

    // Remove the source Quote/Estimate so it cannot be converted again.
    if (source.invoiceId != null) {
      deleteWholeInvoice(source.invoiceId!);
    }

    return newInvoice;
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
    double? discount,
    String? discountType,
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
      element.items![idx].discount = (discount != null && discount > 0) ? discount : null;
      element.items![idx].discountType = (discount != null && discount > 0) ? discountType : null;
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
      if (l.clients == null) continue;
      final data = l.clients!.firstWhere(
        (element) => element.id == id,
        orElse: () => ClientModel(),
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

    final myPrice = (data.items ?? []).fold<num>(
      0,
      (pre, item) => pre.toDouble() + item.lineTotal,
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

    data.items?.removeWhere((element) => element.id == itemId);

    saveInvoice();
    notifyListeners();
  }

  /// Updates the mutable fields of an invoice (date, dueDate, notes, termsConditions, bank, tax).
  void updateInvoiceDetails(
    int invoiceId, {
    String? date,
    String? dueDate,
    String? notes,
    String? termsConditions,
    BankModel? bank,
    double? taxRate,
    String? taxLabel,
  }) {
    final inv = invoice.firstWhere((e) => e.invoiceId == invoiceId);
    if (date != null) inv.date = date;
    inv.dueDate = dueDate;
    inv.notes = notes;
    inv.termsConditions = termsConditions;
    inv.bank = bank;
    inv.taxRate = (taxRate ?? 0) > 0 ? taxRate : null;
    inv.taxLabel = taxLabel;
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
