import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/pdf/pdf_service.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/items_provider.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:invoicemaker/screens/verification_invoice.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/client_model.dart';
import '../models/item_model.dart';
import 'add_client_screen.dart';
import 'add_item_screen.dart';
import 'client_view_screen.dart';
import 'items_screen.dart';

class NewInvoiceScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  final int? invoiceId;

  const NewInvoiceScreen({super.key, this.invoiceId, this.invoice});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String? selectDate;
  final TextEditingController _notesCtrl = TextEditingController();

  bool get _isEditMode => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectDate = customDateFormat(DateTime.now().toString());
      _loadInvoiceData();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _loadInvoiceData() {
    if (!_isEditMode) return;

    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final inv = widget.invoice!;

    selectDate = inv.date;
    invoiceProvider.lastId = inv.invoiceId!;
    _notesCtrl.text = inv.notes ?? '';

    // Load client into working provider so cards display correctly
    for (final client in inv.clients ?? []) {
      clientProvider.selectClient(
        client.name,
        client.address,
        client.phone,
        client.email,
        client.id,
      );
    }

    // Ensure no duplicate items are injected into the live invoice list
    final targetInvoice = invoiceProvider.invoice.firstWhere(
      (i) => i.invoiceId == inv.invoiceId,
      orElse: () => inv,
    );
    for (final itemX in inv.items ?? []) {
      final exists =
          targetInvoice.items?.any((item) => item.id == itemX.id) ?? false;
      if (!exists) {
        targetInvoice.items ??= [];
        targetInvoice.items!.add(ItemModel(
          id: itemX.id,
          price: itemX.price,
          qty: itemX.qty,
          note: itemX.note,
          itemName: itemX.itemName,
          duplicate: false,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ClientProvider, ItemProvider, InvoiceProvider>(
      builder: (context, client, item, invoice, _) {
        return CupertinoPageScaffold(
          backgroundColor: kBackground,
          child: Column(
            children: [
              _buildNavBar(context, client, item, invoice),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.item.isEmpty && !_isEditMode)
                        _buildPageTitle()
                      else
                        _buildMetaRow(invoice),
                      const SizedBox(height: 20),
                      sectionLabel('Client'),
                      _clientCard(client, invoice),
                      const SizedBox(height: 20),
                      sectionLabel('Line Items'),
                      _itemCard(item, invoice),
                      const SizedBox(height: 20),
                      if (item.item.isNotEmpty || _isEditMode) _totalCard(item),
                      const SizedBox(height: 20),
                      sectionLabel('Notes'),
                      _notesCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if ((client.name != null && item.item.isNotEmpty) || _isEditMode)
                _buildBottomBar(context, client, item, invoice),
            ],
          ),
        );
      },
    );
  }

  // ── Nav bar ────────────────────────────────────────────────────────────────
  Widget _buildNavBar(
    BuildContext context,
    ClientProvider client,
    ItemProvider item,
    InvoiceProvider invoice,
  ) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            closeButton(context, () {
              client.clearClientFromList();
              item.item.clear();
              selectDate = null;
              for (final e in invoice.invoice) {
                invoice.lastId = e.invoiceId!;
              }
              setState(() {});
            }),
            const Spacer(),
            if (item.item.isNotEmpty || _isEditMode)
              Text(
                _isEditMode ? 'Edit Invoice' : 'New Invoice',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            const Spacer(),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  // ── Page title (shown only on empty new-invoice state) ─────────────────────
  Widget _buildPageTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'New Invoice',
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
      ),
    );
  }

  // ── Date + invoice-number chips ────────────────────────────────────────────
  Widget _buildMetaRow(InvoiceProvider invoice) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await customDatePicker(context);
              if (date != null) {
                selectDate = customDateFormat(date.toString());
                setState(() {});
              }
            },
            child: _metaChip(
              CupertinoIcons.calendar,
              selectDate ?? customDateFormat(DateTime.now().toString()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metaChip(
            CupertinoIcons.doc_text,
            'Invoice #${_isEditMode ? invoice.lastId : invoice.lastId + 1}',
          ),
        ),
      ],
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kCardDecorationFlat,
      child: Row(
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kTextPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Client card ────────────────────────────────────────────────────────────
  Widget _clientCard(ClientProvider client, InvoiceProvider invoice) {
    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: client.name != null
              ? GestureDetector(
                  onTap: _isEditMode
                      ? null
                      : () => Navigation.go(
                            context,
                            AddClientScreen(
                              client: client.client,
                              name: client.name,
                              address: client.address,
                              email: client.email,
                              phone: client.phone,
                              id: client.lastId,
                              invoice: invoice.invoice,
                              isPredefined: true,
                            ),
                          ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (client.name?.isNotEmpty ?? false)
                                ? client.name![0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                              if (client.email?.isNotEmpty ?? false)
                                Text(
                                  client.email!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: kTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!_isEditMode)
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: kTextSecondary,
                          ),
                      ],
                    ),
                  ),
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (invoice.invoice.isNotEmpty) {
                      Navigation.go(context, ClientViewScreen());
                    } else {
                      Navigation.go(context, AddClientScreen());
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.person_badge_plus,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Add Client',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: kTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Items card ─────────────────────────────────────────────────────────────
  Widget _itemCard(ItemProvider item, InvoiceProvider? invoice) {
    final items = _isEditMode ? widget.invoice!.items! : item.item;

    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              if (items.isNotEmpty)
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: kBorder),
                  itemBuilder: (context, index) {
                    final i = items[index];
                    final lineTotal =
                        ((i.price ?? 0) * (i.qty ?? 1)).toStringAsFixed(2);
                    return InkWell(
                      onTap: () => Navigation.go(
                        context,
                        AddItemScreen(
                          itemModel: i,
                          isUpdate: _isEditMode,
                          invoice: widget.invoice,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    i.itemName ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${i.qty} × \$${i.price}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$$lineTotal',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              if (items.isNotEmpty) const Divider(height: 1, color: kBorder),

              InkWell(
                onTap: () {
                  if (invoice!.invoice.isNotEmpty) {
                    Navigation.go(context, ItemsScreen());
                  } else {
                    Navigation.go(
                      context,
                      AddItemScreen(invoice: widget.invoice),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: items.isEmpty ? kPrimaryLight : kBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.add,
                          color: items.isEmpty ? kPrimary : kTextSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Add Item',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: items.isEmpty ? kPrimary : kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Total card ─────────────────────────────────────────────────────────────
  Widget _totalCard(ItemProvider itemProvider) {
    final items = _isEditMode ? widget.invoice!.items! : itemProvider.item;
    final total = items.fold<double>(
      0,
      (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1)),
    );

    return Container(
      decoration: kCardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(
            'Total',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '\$${total.toStringAsFixed(2)}',
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

  // ── Notes card ─────────────────────────────────────────────────────────────
  Widget _notesCard() {
    return Container(
      decoration: kCardDecoration,
      child: CupertinoTextField(
        controller: _notesCtrl,
        placeholder: 'Add a note to this invoice (optional)…',
        placeholderStyle: GoogleFonts.poppins(fontSize: 14, color: kTextHint),
        style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
        padding: const EdgeInsets.all(16),
        maxLines: 3,
        minLines: 1,
        decoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }

  // ── Bottom action bar ──────────────────────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    ClientProvider client,
    ItemProvider item,
    InvoiceProvider invoice,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          // ── Preview ────────────────────────────────────────────────────────
          Expanded(
            child: AppButton(
              outlined: true,
              txt: 'Preview',
              onTap: () {
                final templateProvider =
                    Provider.of<TemplatesColorsProvider>(context, listen: false);

                // Build a temporary InvoiceModel for preview (create mode)
                // or use the live invoice (edit mode)
                final previewInvoice = _isEditMode
                    ? widget.invoice
                    : InvoiceModel(
                        invoiceId: invoice.lastId + 1,
                        date: selectDate,
                        invoiceStatus: 'UnPaid',
                        notes: _notesCtrl.text.trim().isEmpty
                            ? null
                            : _notesCtrl.text.trim(),
                        items: item.item
                            .map((e) => ItemModel(
                                  itemName: e.itemName,
                                  note: e.note,
                                  price: e.price,
                                  qty: e.qty,
                                  id: e.id,
                                  duplicate: e.duplicate,
                                ))
                            .toList(),
                        clients: client.client
                            .map((e) => ClientModel(
                                  name: e.name,
                                  phone: e.phone,
                                  email: e.email,
                                  address: e.address,
                                  id: e.id,
                                  duplicate: false,
                                ))
                            .toList(),
                      );

                Navigation.go(
                  context,
                  PdfInvoiceScreen(
                    invoice: previewInvoice,
                    provider: templateProvider,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // ── Create / Update ────────────────────────────────────────────────
          Expanded(
            child: AppButton(
              txt: _isEditMode ? 'Update Invoice' : 'Create Invoice',
              onTap: _isEditMode
                  ? () {
                      // Save date + notes changes, then pop back to VerificationInvoice
                      invoice.updateInvoiceDetails(
                        widget.invoice!.invoiceId!,
                        date: selectDate,
                        notes: _notesCtrl.text.trim().isEmpty
                            ? null
                            : _notesCtrl.text.trim(),
                      );
                      client.clearClientFromList();
                      item.item.clear();
                      Navigator.pop(context);
                    }
                  : () async {
                      final businessName =
                          Provider.of<BusinessProvider>(context, listen: false)
                              .saveBusinessModel
                              ?.businessName ??
                          'My Business';

                      await invoice.addInvoice(
                        InvoiceModel(
                          invoiceStatus: 'UnPaid',
                          businessName: businessName,
                          date: selectDate,
                          invoiceId: invoice.lastId,
                          notes: _notesCtrl.text.trim().isEmpty
                              ? null
                              : _notesCtrl.text.trim(),
                          items: item.item
                              .map((e) => ItemModel(
                                    itemName: e.itemName,
                                    note: e.note,
                                    price: e.price,
                                    qty: e.qty,
                                    id: e.id,
                                    duplicate: e.duplicate,
                                  ))
                              .toList(),
                          clients: client.client
                              .map((e) => ClientModel(
                                    name: e.name,
                                    phone: e.phone,
                                    email: e.email,
                                    address: e.address,
                                    id: e.id,
                                    duplicate: duplicate,
                                  ))
                              .toList(),
                        ),
                      );

                      item.item.clear();
                      client.client.clear();
                      client.clearClientFromList();

                      final latestInvoice = invoice.invoice.firstWhere(
                        (e) => e.invoiceId == invoice.lastId,
                      );

                      if (!context.mounted) return;
                      Navigation.go(
                        context,
                        VerificationInvoice(
                          clientModel: latestInvoice.clients!.first,
                          itemModel: latestInvoice.items!.first,
                          invoiceModel: latestInvoice,
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
