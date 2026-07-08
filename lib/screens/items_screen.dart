import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/screens/add_item_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  ItemModel? data;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer<InvoiceProvider>(
      builder: (context, invoice, _) {
        // Collect unique (duplicate == false) items across all invoices,
        // filtered by the current search query.
        final query = _query.toLowerCase();
        final List<ItemModel> uniqueItems = [];
        for (final inv in invoice.invoice) {
          for (final item in inv.items ?? []) {
            if (item.duplicate == true) continue;
            if (query.isNotEmpty &&
                !(item.itemName?.toLowerCase().contains(query) ?? false)) {
              continue;
            }
            uniqueItems.add(item);
          }
        }

        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoNavigationBar(
                    padding: EdgeInsetsDirectional.zero,
                    leading: closeButton(context),
                    middle: Text(
                      context.tr('items'),
                      style: TextStyle(
                        color: buttonColor,
                        fontSize: responseText(context, .05),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Material(
                      color: scaffoldColor,
                      child: InkWell(
                        onTap: () {
                          Navigation.go(
                            context,
                            const AddItemScreen(duplicate: false),
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.add_circled_solid,
                          color: buttonColor,
                        ),
                      ),
                    ),
                  ),

                  customHeight(context, 0.02),

                  CupertinoTextField(
                    controller: _searchCtrl,
                    placeholder: context.tr('search_items'),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        CupertinoIcons.search,
                        size: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    onChanged: (val) => setState(() => _query = val.trim()),
                  ),

                  customHeight(context, 0.02),

                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child:
                        uniqueItems.isEmpty
                            ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  _query.isEmpty
                                      ? context.tr('no_items')
                                      : context.tr('no_results'),
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ),
                            )
                            : Column(
                              children:
                                  uniqueItems
                                      .map(
                                        (item) => CupertinoListTile(
                                          additionalInfo: Text(
                                            item.price.toString(),
                                          ),
                                          onTap: () {
                                            Navigation.go(
                                              context,
                                              AddItemScreen(
                                                itemModel: item,
                                                duplicate: true,
                                              ),
                                            );
                                          },
                                          title: Text(item.itemName ?? ''),
                                        ),
                                      )
                                      .toList(),
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
