// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/navigations.dart';
import 'add_client_screen.dart';

class ClientViewScreen extends StatefulWidget {
  const ClientViewScreen({super.key});

  @override
  State<ClientViewScreen> createState() => _ClientViewScreenState();
}

class _ClientViewScreenState extends State<ClientViewScreen> {
  bool data = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<InvoiceProvider, ClientProvider>(
      builder: (context, invoice, client, _) {
        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: Column(
            children: [
              customHeight(context, .01),

              CupertinoNavigationBar(
                leading: closeButton(context),
                middle: Text('Clients',  style: TextStyle(
                  color: buttonColor,
                  fontSize: responseText(context, .05),
                  fontWeight: FontWeight.bold,
                ),),
                trailing: GestureDetector(
                  onTap: () {
                    duplicate = false;
                    Navigation.go(context, AddClientScreen(isDoublePop: true));
                    setState(() {});
                  },
                  child: Icon(
                    CupertinoIcons.add_circled_solid,
                    color: buttonColor,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(13.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customHeight(context, .02),
                    CupertinoSearchTextField(),
                    customHeight(context, .02),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var l in invoice.invoice) ...[
                            for (var k in l.clients!) ...[
                              if (k.duplicate == false)
                                GestureDetector(
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    await client.selectClient(
                                      k.name,
                                      k.address,
                                      k.phone,
                                      k.email,
                                      k.id,
                                    );

                                    client.client.add(
                                      ClientModel(
                                        name: k.name,
                                        id: k.id,
                                        email: k.email,
                                        address: k.address,
                                        phone: k.phone,
                                        duplicate: true,
                                      ),
                                    );

                                    duplicate = true;
                                    navigator.pop();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(k.name.toString()),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
