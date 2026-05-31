import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';

class ClientProvider extends ChangeNotifier {
  String? name;
  String? address;
  String? phone;
  String? email;
  int? clientId;

  List<ClientModel> client = [];
  List<InvoiceModel> invoice = [];

  int lastId = 0;

  addClient(ClientModel clientModel) {
    client.clear();
    lastId += 1;

    clientId = lastId;
    clientModel.id = lastId;

    client.add(clientModel);

    print('client-->${jsonEncode(client)}');
    notifyListeners();
  }

  selectClient(
    String? clientName,
    String? clientAddress,
    String? clientPhone,
    String? clientEmail,
    int? id,
  ) {
    name = clientName;
    address = clientAddress;
    phone = clientPhone;
    email = clientEmail;
    clientId = id;

    notifyListeners();
  }

  clearClientFromList() {
    name = null;
    address = null;
    phone = null;
    email = null;
    clientId = null;

    notifyListeners();
  }

  int? index;

  updateClient(
    String? clientName,
    String? clientAddress,
    String? clientPhone,
    String? clientEmail,
    int? id,
  ) {
    index = client.indexWhere((element) => element.id == id);

    if (index != -1) {
      client[index!].name = clientName;
      client[index!].phone = clientPhone;
      client[index!].email = clientEmail;
      client[index!].address = clientAddress;

      notifyListeners();
    } else {
      print("Client with id $id not found.");
    }
  }
}
