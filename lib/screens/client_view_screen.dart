import 'package:flutter/cupertino.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:provider/provider.dart';

import '../services/navigations.dart';
import 'add_client_screen.dart';

class ClientViewScreen extends StatefulWidget {
  const ClientViewScreen({super.key});

  @override
  State<ClientViewScreen> createState() => _ClientViewScreenState();
}

class _ClientViewScreenState extends State<ClientViewScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<InvoiceProvider, ClientProvider>(
      builder: (context, invoice, client, _) {
        // Collect unique (duplicate == false) clients across all invoices,
        // filtered by the current search query.
        final query = _query.toLowerCase();
        final List<ClientModel> uniqueClients = [];
        for (final inv in invoice.invoice) {
          for (final k in inv.clients ?? []) {
            if (k.duplicate == true) continue;
            if (query.isNotEmpty &&
                !(k.name?.toLowerCase().contains(query) ?? false)) {
              continue;
            }
            uniqueClients.add(k);
          }
        }

        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: Column(
            children: [
              customHeight(context, .01),

              CupertinoNavigationBar(
                leading: closeButton(context),
                middle: Text(
                  'Clients',
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: responseText(context, .05),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: GestureDetector(
                  onTap: () {
                    Navigation.go(
                      context,
                      const AddClientScreen(isDoublePop: true),
                    );
                  },
                  child: const Icon(
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
                    CupertinoSearchTextField(
                      controller: _searchCtrl,
                      onChanged: (val) =>
                          setState(() => _query = val.trim()),
                    ),
                    customHeight(context, .02),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: uniqueClients.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  _query.isEmpty
                                      ? 'No clients yet'
                                      : 'No results',
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: uniqueClients
                                  .map(
                                    (k) => GestureDetector(
                                      onTap: () {
                                        // Replace any stale working client before selecting
                                        client.client.clear();
                                        client.selectClient(
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
                                            duplicate: false,
                                          ),
                                        );
                                        Navigator.of(context).pop();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(k.name ?? ''),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
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
