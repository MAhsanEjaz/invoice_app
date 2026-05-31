import 'client_model.dart';
import 'item_model.dart';

class InvoiceModel {
  int? invoiceId;
  String? businessName;
  String? date;
  String? invoiceStatus;
  List<ItemModel>? items;
  List<ClientModel>? clients;

  InvoiceModel({
    this.items,
    this.businessName,
    this.date,
    this.clients,
    this.invoiceId,
    this.invoiceStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'businessName': businessName,
      'date': date,
      'invoiceStatus': invoiceStatus,
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
