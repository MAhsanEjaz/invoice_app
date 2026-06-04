import 'client_model.dart';
import 'item_model.dart';

class InvoiceModel {
  int? invoiceId;
  String? businessId;
  String? businessName;
  String? date;
  String? invoiceStatus;
  String? notes;
  double? receivedAmount;
  double? discount;
  List<ItemModel>? items;
  List<ClientModel>? clients;

  InvoiceModel({
    this.items,
    this.businessId,
    this.businessName,
    this.date,
    this.clients,
    this.invoiceId,
    this.invoiceStatus,
    this.notes,
    this.receivedAmount,
    this.discount,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'businessId': businessId,
      'businessName': businessName,
      'date': date,
      'invoiceStatus': invoiceStatus,
      'notes': notes,
      'receivedAmount': receivedAmount,
      'discount': discount,
      'clients': clients?.map((e) => e.toJson()).toList(),
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId'],
      businessId: json['businessId'] as String?,
      invoiceStatus: json['invoiceStatus'],
      date: json['date'],
      businessName: json['businessName'],
      notes: json['notes'],
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      clients:
          (json['clients'] as List<dynamic>?)
              ?.map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
