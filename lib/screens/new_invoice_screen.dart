import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/pdf/pdf_service.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/items_provider.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:invoicemaker/screens/verification_invoice.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/business_model.dart';
import '../models/client_model.dart';
import '../models/item_model.dart';
import '../models/service_model.dart';
import '../models/bank_model.dart';
import '../providers/bank_provider.dart';
import '../providers/saved_client_provider.dart';
import '../providers/service_provider.dart';
import 'add_client_screen.dart';
import 'add_item_screen.dart';
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
  BusinessModel? _selectedBusiness;
  BankModel? _selectedBank;

  bool get _isEditMode => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectDate = customDateFormat(DateTime.now().toString());
      _loadInvoiceData();
      // Default to the default business for new invoices
      if (!_isEditMode) {
        final bp = Provider.of<BusinessProvider>(context, listen: false);
        _selectedBusiness = bp.defaultBusiness ?? bp.activeBusiness;
      }
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
                      const SizedBox(height: 20),
                      sectionLabel('Payment Details'),
                      _bankCard(),
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
    return Column(
      children: [
        Row(
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
        ),
        if (!_isEditMode) ...[
          const SizedBox(height: 10),
          _buildBusinessSelector(),
        ],
      ],
    );
  }

  Widget _buildBusinessSelector() {
    final bp = Provider.of<BusinessProvider>(context, listen: false);
    final businesses = bp.businesses;
    if (businesses.length <= 1) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showBusinessPicker(bp),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: kCardDecorationFlat,
        child: Row(
          children: [
            const Icon(CupertinoIcons.building_2_fill, size: 16, color: kPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedBusiness?.businessName ?? 'Select Business',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 13,
              color: kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showBusinessPicker(BusinessProvider bp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Invoice From',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bp.businesses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final b = bp.businesses[i];
                  final isSel = _selectedBusiness?.id == b.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedBusiness = b);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel ? kPrimaryLight : kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? kPrimary : kBorder,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSel ? kPrimary : kBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (b.businessName?.isNotEmpty ?? false)
                                  ? b.businessName![0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : kTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              b.businessName ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary,
                              ),
                            ),
                          ),
                          if (b.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Default',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            isSel
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: isSel ? kPrimary : kTextHint,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
                  onTap: () => _showClientPicker(client),
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
                    final sym =
                        Provider.of<CurrencyProvider>(context).symbol;
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
                                    '${i.qty} × $sym${i.price}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$sym$lineTotal',
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

              const Divider(height: 1, color: kBorder),

              InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                onTap: () => _showServicePicker(item, invoice!),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: kBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.tag,
                          color: kTextSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Add Service',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
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

  void _showBankPicker() {
    final banks = Provider.of<BankProvider>(context, listen: false).banks;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankPickerSheet(
        banks: banks,
        selectedId: _selectedBank?.id,
        onSelect: (b) => setState(() => _selectedBank = b),
      ),
    );
  }

  void _showClientPicker(ClientProvider client) {
    final savedClients =
        Provider.of<SavedClientProvider>(context, listen: false).clients;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientPickerSheet(
        savedClients: savedClients,
        onSelect: (c) {
          client.selectClient(c.name, c.address, c.phone, c.email, c.id);
          client.client.add(ClientModel(
            name: c.name,
            id: c.id,
            email: c.email,
            address: c.address,
            phone: c.phone,
            duplicate: false,
          ));
        },
        onAddNew: () => Navigation.go(context, const AddClientScreen()),
      ),
    );
  }

  void _showServicePicker(ItemProvider item, InvoiceProvider invoice) {
    final services =
        Provider.of<ServiceProvider>(context, listen: false).services;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServicePickerSheet(
        services: services,
        onConfirm: (selected) {
          for (final service in selected) {
            final itemModel = ItemModel(
              itemName: service.name,
              note: service.description,
              price: service.price ?? 0,
              qty: 1,
              duplicate: false,
            );
            if (_isEditMode) {
              invoice.addMoreInvoices(widget.invoice!.invoiceId!, itemModel);
            } else {
              item.addItems(itemModel);
            }
          }
        },
      ),
    );
  }

  // ── Total card ─────────────────────────────────────────────────────────────
  Widget _totalCard(ItemProvider itemProvider) {
    final sym =
        Provider.of<CurrencyProvider>(context).symbol;
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
            '$sym${total.toStringAsFixed(2)}',
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

  // ── Bank card ──────────────────────────────────────────────────────────────
  Widget _bankCard() {
    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: _selectedBank != null
              ? InkWell(
                  onTap: _isEditMode ? null : () => _showBankPicker(),
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
                            CupertinoIcons.creditcard,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedBank!.title ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                              Text(
                                '${_selectedBank!.bankName}  •  ${_selectedBank!.accountNumber}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isEditMode) ...[
                          GestureDetector(
                            onTap: () => setState(() => _selectedBank = null),
                            child: const Icon(
                              CupertinoIcons.xmark_circle,
                              size: 20,
                              color: kTextHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isEditMode ? null : () => _showBankPicker(),
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
                            CupertinoIcons.creditcard,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Add Bank Account',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: kTextSecondary,
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
                        bank: _selectedBank,
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
                      final bp =
                          Provider.of<BusinessProvider>(context, listen: false);
                      final biz = _selectedBusiness ?? bp.defaultBusiness ?? bp.activeBusiness;

                      await invoice.addInvoice(
                        InvoiceModel(
                          invoiceStatus: 'UnPaid',
                          businessId: biz?.id,
                          businessName: biz?.businessName ?? 'My Business',
                          date: selectDate,
                          invoiceId: invoice.lastId,
                          notes: _notesCtrl.text.trim().isEmpty
                              ? null
                              : _notesCtrl.text.trim(),
                          bank: _selectedBank,
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

class _ServicePickerSheet extends StatefulWidget {
  final List<ServiceModel> services;
  final void Function(List<ServiceModel>) onConfirm;

  const _ServicePickerSheet({
    required this.services,
    required this.onConfirm,
  });

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Select Services',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_selected.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (widget.services.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.tag,
                      size: 40,
                      color: kTextHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No services added yet.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Go to Settings → Items & Services to add some.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kTextHint,
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.services.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final service = widget.services[index];
                    final isChosen = _selected.contains(service.id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isChosen) {
                          _selected.remove(service.id);
                        } else {
                          _selected.add(service.id!);
                        }
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isChosen ? kPrimaryLight : kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isChosen ? kPrimary : kBorder,
                            width: isChosen ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isChosen ? kPrimary : kBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (service.name?.isNotEmpty ?? false)
                                    ? service.name![0].toUpperCase()
                                    : 'S',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isChosen
                                      ? Colors.white
                                      : kTextSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  if (service.description?.isNotEmpty ?? false)
                                    Text(
                                      service.description!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: kTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (service.price != null)
                              Text(
                                '\$${service.price!.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isChosen
                                      ? kPrimary
                                      : kTextSecondary,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              isChosen
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              color: isChosen ? kPrimary : kTextHint,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppButton(
                txt: _selected.isEmpty
                    ? 'Select Services'
                    : 'Add ${_selected.length} Service${_selected.length > 1 ? 's' : ''}',
                onTap: _selected.isEmpty
                    ? null
                    : () {
                        final chosen = widget.services
                            .where((s) => _selected.contains(s.id))
                            .toList();
                        Navigator.pop(context);
                        widget.onConfirm(chosen);
                      },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BankPickerSheet extends StatelessWidget {
  final List<BankModel> banks;
  final int? selectedId;
  final void Function(BankModel) onSelect;

  const _BankPickerSheet({
    required this.banks,
    required this.onSelect,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Bank Account',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (banks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.creditcard,
                      size: 40,
                      color: kTextHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No bank accounts added yet.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Go to Settings → Bank Accounts to add some.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kTextHint,
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: banks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = banks[index];
                    final isSelected = b.id == selectedId;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(b);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimaryLight : kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? kPrimary : kBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? kPrimary : kBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.creditcard,
                                color:
                                    isSelected ? Colors.white : kTextSecondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${b.bankName}  •  ${b.accountNumber}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: kTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              color: isSelected ? kPrimary : kTextHint,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ClientPickerSheet extends StatelessWidget {
  final List<ClientModel> savedClients;
  final void Function(ClientModel) onSelect;
  final VoidCallback onAddNew;

  const _ClientPickerSheet({
    required this.savedClients,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Client',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (savedClients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.person_2,
                      size: 40,
                      color: kTextHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No saved clients yet.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Go to Settings → Clients to add some.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: kTextHint,
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: savedClients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = savedClients[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(c);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kPrimaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (c.name?.isNotEmpty ?? false)
                                    ? c.name![0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: kTextPrimary,
                                    ),
                                  ),
                                  if (c.email?.isNotEmpty ?? false)
                                    Text(
                                      c.email!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: kTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else if (c.phone?.isNotEmpty ?? false)
                                    Text(
                                      c.phone!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: kTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppButton(
                outlined: true,
                txt: 'Add New Client',
                onTap: () {
                  Navigator.pop(context);
                  onAddNew();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
