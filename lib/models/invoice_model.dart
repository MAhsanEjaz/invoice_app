import 'bank_model.dart';
import 'client_model.dart';
import 'item_model.dart';

class InvoiceModel {
  int? invoiceId;
  // Custom formatted number e.g. "INV-2024-001". Null = fall back to invoiceId display.
  String? invoiceNumber;
  String? businessId;
  String? businessName;
  String? date;
  String? dueDate;
  String? invoiceStatus;
  String? notes;
  String? termsConditions;
  double? receivedAmount;
  double? discount;
  // Tax rate as a percentage, e.g. 18.0 for 18%. Null / 0 = no tax.
  double? taxRate;
  // Display label for tax, e.g. "GST", "VAT". Null defaults to "Tax".
  String? taxLabel;
  List<ItemModel>? items;
  List<ClientModel>? clients;
  BankModel? bank;
  // 'Invoice' | 'Quote' | 'Estimate' — null treated as 'Invoice' for backward compat
  String? documentType;
  // Recurring invoice fields
  bool? isRecurring;
  String? recurringInterval; // 'weekly' | 'monthly' | 'custom'
  int? recurringCustomDays; // Only used when recurringInterval == 'custom'
  String?
  nextRecurringDate; // ISO yyyy-MM-dd — the date when next copy is created

  InvoiceModel({
    this.items,
    this.businessId,
    this.businessName,
    this.date,
    this.dueDate,
    this.clients,
    this.invoiceId,
    this.invoiceNumber,
    this.invoiceStatus,
    this.notes,
    this.termsConditions,
    this.receivedAmount,
    this.discount,
    this.taxRate,
    this.taxLabel,
    this.bank,
    this.documentType,
    this.isRecurring,
    this.recurringInterval,
    this.recurringCustomDays,
    this.nextRecurringDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'businessId': businessId,
      'businessName': businessName,
      'date': date,
      'dueDate': dueDate,
      'invoiceStatus': invoiceStatus,
      'notes': notes,
      'termsConditions': termsConditions,
      'receivedAmount': receivedAmount,
      'discount': discount,
      'taxRate': taxRate,
      'taxLabel': taxLabel,
      'clients': clients?.map((e) => e.toJson()).toList(),
      'items': items?.map((e) => e.toJson()).toList(),
      'bank': bank?.toJson(),
      'documentType': documentType,
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'recurringCustomDays': recurringCustomDays,
      'nextRecurringDate': nextRecurringDate,
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId'],
      invoiceNumber: json['invoiceNumber'] as String?,
      businessId: json['businessId'] as String?,
      invoiceStatus: json['invoiceStatus'],
      date: json['date'],
      dueDate: json['dueDate'] as String?,
      businessName: json['businessName'],
      notes: json['notes'],
      termsConditions: json['termsConditions'] as String?,
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      taxRate: (json['taxRate'] as num?)?.toDouble(),
      taxLabel: json['taxLabel'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      clients:
          (json['clients'] as List<dynamic>?)
              ?.map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      bank:
          json['bank'] != null
              ? BankModel.fromJson(json['bank'] as Map<String, dynamic>)
              : null,
      documentType: json['documentType'] as String?,
      isRecurring: json['isRecurring'] as bool?,
      recurringInterval: json['recurringInterval'] as String?,
      recurringCustomDays: json['recurringCustomDays'] as int?,
      nextRecurringDate: json['nextRecurringDate'] as String?,
    );
  }
}
