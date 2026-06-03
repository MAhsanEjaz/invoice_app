import 'client_model.dart';
import 'item_model.dart';

class InvoiceModel {
  int? invoiceId;
  String? businessName;
  String? date;
  String? invoiceStatus;
  String? notes;
  double? receivedAmount;
  List<ItemModel>? items;
  List<ClientModel>? clients;

  InvoiceModel({
    this.items,
    this.businessName,
    this.date,
    this.clients,
    this.invoiceId,
    this.invoiceStatus,
    this.notes,
    this.receivedAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'businessName': businessName,
      'date': date,
      'invoiceStatus': invoiceStatus,
      'notes': notes,
      'receivedAmount': receivedAmount,
      'clients': clients?.map((e) => e.toJson()).toList(),
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId'],
      invoiceStatus: json['invoiceStatus'],
      date: json['date'],
      businessName: json['businessName'],
      notes: json['notes'],
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble(),
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
