import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/models/item_model.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/items_provider.dart';
import 'package:provider/provider.dart';

import '../models/invoice_model.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_filed.dart';

class AddItemScreen extends StatefulWidget {
  final ItemModel? itemModel;
  final bool? isUpdate;
  final bool duplicate;
  final InvoiceModel? invoice;

  const AddItemScreen({
    super.key,
    this.itemModel,
    this.invoice,
    this.isUpdate = false,
    this.duplicate = false,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final itemCont = TextEditingController();
  final noteCont = TextEditingController();
  final priceCont = TextEditingController();
  final qtyCont = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.itemModel != null) {
      itemCont.text = widget.itemModel!.itemName ?? '';
      noteCont.text = widget.itemModel!.note ?? '';
      priceCont.text = widget.itemModel!.price?.toString() ?? '';
      qtyCont.text = widget.itemModel!.qty.toString();
    } else {
      priceCont.text = '1';
      qtyCont.text = '1';
    }
  }

  @override
  void dispose() {
    itemCont.dispose();
    noteCont.dispose();
    priceCont.dispose();
    qtyCont.dispose();
    super.dispose();
  }

  double get _lineTotal {
    final price = double.tryParse(priceCont.text) ?? 0;
    final qty = int.tryParse(qtyCont.text) ?? 0;
    return price * qty;
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    return Consumer2<ItemProvider, InvoiceProvider>(
      builder: (context, item, invoice, _) {
        final isEditing =
            widget.itemModel != null && widget.duplicate == false;

        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: Column(
            children: [
              _buildNavBar(cl, isEditing),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionLabel(context, 'Item Details'),
                      _buildDescriptionCard(cl),
                      const SizedBox(height: 20),
                      sectionLabel(context, 'Pricing'),
                      _buildPricingCard(cl),
                      const SizedBox(height: 20),
                      _buildTotalCard(),
                      if (widget.itemModel != null) ...[
                        const SizedBox(height: 24),
                        _buildDeleteButton(cl, item, invoice),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(cl, item, invoice, isEditing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavBar(AppColors cl, bool isEditing) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            closeButton(context),
            const Spacer(),
            Text(
              isEditing ? 'Edit Item' : 'New Item',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cl.textPrimary,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          AppTextFiled(
            controller: itemCont,
            placeholder: 'Item or service name',
            autofocus: true,
          ),
          Divider(height: 1, color: cl.border, indent: 16, endIndent: 16),
          AppTextFiled(
            controller: noteCont,
            placeholder: 'Notes (optional)',
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          AppTextFiled(
            controller: priceCont,
            placeholder: 'Unit Price',
            textInputType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          Divider(height: 1, color: cl.border, indent: 16, endIndent: 16),
          AppTextFiled(
            controller: qtyCont,
            placeholder: 'Quantity',
            textInputType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final sym = Provider.of<CurrencyProvider>(context).symbol;
    return Container(
      decoration: context.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(
            'Line Total',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '$sym${_lineTotal.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(
      AppColors cl, ItemProvider item, InvoiceProvider invoice) {
    return GestureDetector(
      onTap: () {
        if (widget.duplicate == true) {
          customCupertinoDialog(context, () {
            invoice.deleteExistingItems(widget.itemModel!.id);
          });
        } else {
          customCupertinoDialog(context, () async {
            if (widget.isUpdate == true &&
                widget.invoice != null &&
                widget.itemModel?.id != null) {
              await invoice.deleteInvoice(
                widget.invoice!.invoiceId!,
                widget.itemModel!.id!,
              );
            } else if (widget.itemModel != null) {
              await item.deleteItems(
                  widget.itemModel!, widget.itemModel!.id ?? 0);
            }
            if (!mounted) return;
            Navigator.pop(context);
          });
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cl.dangerBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDangerColor.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.delete, color: kDangerColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Remove Item',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kDangerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    AppColors cl,
    ItemProvider item,
    InvoiceProvider invoice,
    bool isEditing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cl.surface,
        border: Border(top: BorderSide(color: cl.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: AppButton(
        txt: isEditing ? 'Update Item' : 'Save Item',
        onTap: () {
          if (widget.duplicate == true && widget.itemModel != null) {
            invoice.addExistingItemWithId(
              widget.itemModel!,
              item.item,
              itemCont.text.trim(),
              qtyCont.text,
              priceCont.text,
              noteCont.text.trim(),
            );
          }

          if (widget.itemModel != null && widget.duplicate == false) {
            item.updateItems(
              itemCont.text,
              priceCont.text,
              qtyCont.text,
              noteCont.text,
              widget.itemModel,
            );
          } else {
            if (widget.invoice == null && widget.duplicate == false) {
              item.addItems(
                ItemModel(
                  note: noteCont.text.trim(),
                  id: item.lastId,
                  qty: int.tryParse(qtyCont.text),
                  price: double.tryParse(priceCont.text),
                  itemName: itemCont.text,
                  duplicate: false,
                ),
              );
            } else {
              if (widget.duplicate == false) {
                invoice.addMoreInvoices(
                  widget.invoice!.invoiceId!,
                  ItemModel(
                    id: invoice.newItemId,
                    note: noteCont.text.trim(),
                    qty: int.tryParse(qtyCont.text),
                    price: double.tryParse(priceCont.text),
                    itemName: itemCont.text,
                    duplicate: false,
                  ),
                );
              }
            }
          }

          if (widget.itemModel?.id != null && widget.duplicate == false) {
            invoice.itemUpdate(
              widget.itemModel!.id!,
              itemCont.text,
              noteCont.text,
              double.tryParse(priceCont.text) ?? 0,
              int.tryParse(qtyCont.text) ?? 1,
            );
          }

          if (invoice.invoice.isNotEmpty) {
            Navigator.pop(context);
            Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }

          setState(() {});
        },
      ),
    );
  }
}
