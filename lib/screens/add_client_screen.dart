// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:invoicemaker/widgets/app_text_filed.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class AddClientScreen extends StatefulWidget {
  String? name;
  String? phone;
  String? email;
  String? address;
  int? id;

  bool? isPredefined;
  bool? isDoublePop;

  List<ClientModel>? client = [];
  List<InvoiceModel>? invoice = [];

  AddClientScreen({
    super.key,
    this.name,
    this.phone,
    this.email,
    this.address,
    this.id,
    this.isPredefined = false,
    this.client,
    this.isDoublePop = false,
    this.invoice,
  });

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  ClientModel? id;

  getId() {
    if (widget.isPredefined == true) {
      for (var element in widget.invoice!) {
        id = element.clients!.firstWhere(
          (myInvoice) => myInvoice.name == widget.name,
          orElse: () => ClientModel(), // avoid crash
        );
        print('this time working with${id!.id}${id!.name}');
      }

      id = widget.client?.firstWhere(
        (element) => element.name == widget.name,
        orElse: () => ClientModel(),
      );
    } else if (widget.isPredefined == false) {
      id = widget.client?.firstWhere(
        (element) => element.name == widget.name,
        orElse: () => ClientModel(),
      );

      print('this time working without');
    }

    if (id?.id != null) {
      print('matchedId--->${jsonEncode(id!.id)}');

      fetchId = id!.id!;
      print('fetchId-->$fetchId');
    } else {
      print('idNOt MAtched');
    }
  }

  // }

  initializeData() {
    if (widget.name != null) {
      nameCont.text = widget.name!;
      phoneCont.text = widget.phone ?? '';
      emailCont.text = widget.email ?? '';
      addressCont.text = widget.address ?? '';
    }
    getId();
  }

  TextEditingController nameCont = TextEditingController();
  TextEditingController phoneCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController addressCont = TextEditingController();

  Future<void> _pickContact() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contact = await FlutterContacts.openExternalPick();

        nameCont.text = contact!.displayName;
        phoneCont.text = contact.phones.first.number;
        emailCont.text = contact.emails.first.address;
        addressCont.text = contact.addresses.first.address;

        setState(() {});
      } else {
        openAppSettings();
      }
    } catch (err) {
      await Permission.contacts.request();
      print('errorOccured-->$err');
    }
  }

  int fetchId = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClientProvider, InvoiceProvider>(
      builder: (context, client, invoice, _) {
        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: CupertinoNavigationBar(
                  automaticallyImplyLeading: false,
                  // prevents default back button
                  leading: closeButton(context),
                  middle: Text(
                    client.name != null ? 'Edit Client' : 'New Client',
                    style: TextStyle(
                      color: buttonColor,
                      fontSize: responseText(context, .05),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      addClientCard(),

                      client.name != null
                          ? deleteContact(client)
                          : SizedBox.shrink(),
                    ],
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AppButton(
                    onTap: () {
                      print('idd-->${widget.id}');
                      if (widget.id == null && widget.name == null) {
                        client.addClient(
                          ClientModel(
                            email: emailCont.text.trim(),
                            address: addressCont.text.trim(),
                            phone: phoneCont.text.trim(),
                            name: nameCont.text.trim(),
                            duplicate: false,
                          ),
                        );
                      } else {
                        if (widget.isPredefined == true) {
                          invoice.updateClient(
                            fetchId,
                            nameCont.text.trim(),
                            phoneCont.text.trim(),
                            emailCont.text.trim(),
                            addressCont.text.trim(),
                          );

                          client.updateClient(
                            nameCont.text.trim(),
                            addressCont.text.trim(),
                            phoneCont.text.trim(),
                            emailCont.text.trim(),
                            fetchId,
                          );
                        } else {
                          client.updateClient(
                            nameCont.text.trim(),
                            addressCont.text.trim(),
                            phoneCont.text.trim(),
                            emailCont.text.trim(),
                            fetchId,
                          );
                        }
                      }

                      print('email--->${emailCont.text}');

                      client.selectClient(
                        nameCont.text.trim(),
                        addressCont.text.trim(),
                        phoneCont.text.trim(),
                        emailCont.text.trim(),
                        fetchId,
                      );

                      if (widget.isDoublePop == true) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    txt: client.name != null ? 'Save Changes' : 'Save Client',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget deleteContact(ClientProvider client) {
    return GestureDetector(
      onTap: () {
        customCupertinoDialog(context, () async {
          await client.clearClientFromList();
          Navigator.pop(context);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.delete_solid, color: Colors.red, size: 16),
                SizedBox(width: 10),
                Text(
                  'Delete from invoice',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget addClientCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 5),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextFiled(controller: nameCont, placeholder: 'Client Name'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11.0),
                  child: Divider(height: 0, color: Colors.black12),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 11,
                  ),
                  child: SizedBox(
                    height: 39,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _pickContact();
                      },
                      label: Text(
                        'Import from contacts',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.contact_phone,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          customHeight(context, 0.02),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                AppTextFiled(
                  controller: phoneCont,
                  placeholder: 'Phone',
                  textInputType: TextInputType.phone,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11.0),
                  child: Divider(height: 0, color: Colors.black12),
                ),
                AppTextFiled(
                  controller: emailCont,
                  placeholder: 'E-Mail',
                  textInputType: TextInputType.emailAddress,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11.0),
                  child: Divider(height: 0, color: Colors.black12),
                ),
                AppTextFiled(
                  controller: addressCont,
                  placeholder: 'Address',
                  textInputType: TextInputType.streetAddress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
