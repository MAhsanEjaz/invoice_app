import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/items_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/terms_provider.dart';
import 'package:invoicemaker/providers/pdf_templates_colors_provider.dart';
import 'package:invoicemaker/screens/invoice_preview_screen.dart';
import 'package:invoicemaker/screens/verification_invoice.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';
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
  String? _dueDate;
  bool _includeTerms = false;
  final TextEditingController _notesCtrl = TextEditingController();
  BusinessModel? _selectedBusiness;
  BankModel? _selectedBank;
  // 'Invoice' | 'Quote' | 'Estimate'
  String _documentType = 'Invoice';

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

    final invoiceProvider = Provider.of<InvoiceProvider>(
      context,
      listen: false,
    );
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final inv = widget.invoice!;

    selectDate = inv.date;
    _dueDate = inv.dueDate;
    _includeTerms = inv.termsConditions?.isNotEmpty ?? false;
    _notesCtrl.text = inv.notes ?? '';
    _selectedBank = inv.bank;
    _documentType = inv.documentType ?? 'Invoice';

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
        targetInvoice.items!.add(
          ItemModel(
            id: itemX.id,
            price: itemX.price,
            qty: itemX.qty,
            note: itemX.note,
            itemName: itemX.itemName,
            duplicate: false,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Consumer3<ClientProvider, ItemProvider, InvoiceProvider>(
      builder: (context, client, item, invoice, _) {
        return CupertinoPageScaffold(
          backgroundColor: context.colors.background,
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
                      if (!_isEditMode) _buildDocTypeSelector(),
                      if (item.item.isEmpty && !_isEditMode)
                        _buildPageTitle()
                      else
                        _buildMetaRow(invoice),
                      const SizedBox(height: 20),
                      sectionLabel(context, context.tr('client')),
                      _clientCard(client, invoice),
                      const SizedBox(height: 20),
                      sectionLabel(context, context.tr('line_items')),
                      _itemCard(item, invoice),
                      const SizedBox(height: 20),
                      if (item.item.isNotEmpty || _isEditMode) _totalCard(item),
                      const SizedBox(height: 20),
                      sectionLabel(context, context.tr('notes')),
                      _notesCard(),
                      const SizedBox(height: 20),
                      _buildTermsToggle(),
                      sectionLabel(context, context.tr('pdf_payment_details')),
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
              client.clearClientFromList(); // now also clears client.client list
              item.item.clear();
              selectDate = null;
              setState(() {});
            }),
            const Spacer(),
            if (item.item.isNotEmpty || _isEditMode)
              Text(
                _isEditMode
                    ? (_documentType == 'Quote'
                        ? context.tr('edit_quote')
                        : _documentType == 'Estimate'
                            ? context.tr('edit_estimate')
                            : context.tr('edit_invoice'))
                    : (_documentType == 'Quote'
                        ? context.tr('new_quote')
                        : _documentType == 'Estimate'
                            ? context.tr('new_estimate')
                            : context.tr('new_invoice')),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            const Spacer(),
            const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  // ── Document type selector ─────────────────────────────────────────────────
  Widget _buildDocTypeSelector() {
    final types = [
      ('Invoice', context.tr('doc_invoice')),
      ('Quote', context.tr('doc_quote')),
      ('Estimate', context.tr('doc_estimate')),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: types.map((entry) {
          final key = entry.$1;
          final label = entry.$2;
          final isSelected = _documentType == key;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: key != 'Estimate' ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => setState(() => _documentType = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? kPrimary : context.colors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Page title (shown only on empty new-invoice state) ─────────────────────
  Widget _buildPageTitle() {
    String titleKey;
    if (_documentType == 'Quote') {
      titleKey = 'new_quote';
    } else if (_documentType == 'Estimate') {
      titleKey = 'new_estimate';
    } else {
      titleKey = 'new_invoice';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        context.tr(titleKey),
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  // ── Date + invoice-number + due-date chips ────────────────────────────────
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
                () {
                  final num = _isEditMode
                      ? (widget.invoice!.invoiceId ?? invoice.lastId)
                      : invoice.lastId + 1;
                  if (_documentType == 'Quote') return '${context.tr('quote_no')}$num';
                  if (_documentType == 'Estimate') return '${context.tr('estimate_no')}$num';
                  return '${context.tr('pdf_invoice_no')}$num';
                }(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final date = await customDatePicker(context, allowFuture: true);
            if (date != null) {
              setState(() => _dueDate = customDateFormat(date.toString()));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: context.cardDecorationFlat,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 16,
                  color: _dueDate != null ? kPrimary : context.colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dueDate != null
                        ? '${context.tr('due_prefix')}$_dueDate'
                        : context.tr('set_due_date'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _dueDate != null ? context.colors.textPrimary :context.colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_dueDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _dueDate = null),
                    child: Icon(
                      CupertinoIcons.xmark_circle,
                      size: 16,
                      color: context.colors.textHint,
                    ),
                  )
                else
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 13,
                    color: context.colors.textSecondary,
                  ),
              ],
            ),
          ),
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
        decoration: context.cardDecorationFlat,
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.building_2_fill,
              size: 16,
              color: kPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedBusiness?.businessName ?? context.tr('select_business'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 13,
              color: context.colors.textSecondary,
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
      builder:
          (_) => Container(
            decoration: BoxDecoration(
              color: context.colors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.tr('invoice_from'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
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
                            color: isSel ? context.colors.primaryLight :context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? kPrimary : context.colors.border,
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
                                  color: isSel ? kPrimary : context.colors.background,
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
                                    color:
                                        isSel ? Colors.white : context.colors.textSecondary,
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
                                    color: context.colors.textPrimary,
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
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.tr('default_label'),
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
                                color: isSel ? kPrimary : context.colors.textHint,
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
      decoration: context.cardDecorationFlat,
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
                color: context.colors.textPrimary,
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
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child:
              client.name != null
                  ? GestureDetector(
                    onTap:
                        _isEditMode
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
                              color: context.colors.primaryLight,
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
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                if (client.email?.isNotEmpty ?? false)
                                  Text(
                                    client.email!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!_isEditMode)
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: context.colors.textSecondary,
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
                              color: context.colors.primaryLight,
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
                            context.tr('add_client'),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: context.colors.textSecondary,
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
      decoration: context.cardDecoration,
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
                  separatorBuilder:
                      (_, __) => Divider(height: 1, color: context.colors.border),
                  itemBuilder: (context, index) {
                    final i = items[index];
                    final sym = Provider.of<CurrencyProvider>(context).symbol;
                    final lineTotal = ((i.price ?? 0) * (i.qty ?? 1))
                        .toStringAsFixed(2);
                    return InkWell(
                      onTap:
                          () => Navigation.go(
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
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${i.qty} × $sym${i.price}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: context.colors.textSecondary,
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
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              if (items.isNotEmpty) Divider(height: 1, color: context.colors.border),

              InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                onTap: () => _showAddLineItemPicker(item, invoice!),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: items.isEmpty ? context.colors.primaryLight : context.colors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.add,
                          color: items.isEmpty ? kPrimary : context.colors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        context.tr('add_item'),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: items.isEmpty ? kPrimary : context.colors.textSecondary,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer<BankProvider>(
        builder: (_, bankProvider, __) => _BankPickerSheet(
          banks: bankProvider.banks,
          selectedId: _selectedBank?.id,
          onSelect: (b) => setState(() => _selectedBank = b),
        ),
      ),
    );
  }

  void _showClientPicker(ClientProvider client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer<SavedClientProvider>(
        builder: (_, savedClientProvider, __) => _ClientPickerSheet(
          savedClients: savedClientProvider.clients,
          onSelect: (c) {
            client.client.clear(); // replace any previously-set client
            client.selectClient(c.name, c.address, c.phone, c.email, c.id);
            client.client.add(
              ClientModel(
                name: c.name,
                id: c.id,
                email: c.email,
                address: c.address,
                phone: c.phone,
                duplicate: false,
              ),
            );
          },
          onAddNew: () => Navigation.go(context, const AddClientScreen()),
        ),
      ),
    );
  }

  void _showAddLineItemPicker(ItemProvider item, InvoiceProvider invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer<ServiceProvider>(
        builder: (_, serviceProvider, __) => _AddLineItemSheet(
          services: serviceProvider.services,
          onNewItem: () {
            Navigator.pop(context);
            if (invoice.invoice.isNotEmpty) {
              Navigation.go(context, ItemsScreen());
            } else {
              Navigation.go(context, AddItemScreen(invoice: widget.invoice));
            }
          },
          onConfirmServices: (selected) {
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
      ),
    );
  }

  // ── Total card ─────────────────────────────────────────────────────────────
  Widget _totalCard(ItemProvider itemProvider) {
    final sym = Provider.of<CurrencyProvider>(context).symbol;
    final items = _isEditMode ? widget.invoice!.items! : itemProvider.item;
    final total = items.fold<double>(
      0,
      (s, i) => s + ((i.price ?? 0) * (i.qty ?? 1)),
    );

    return Container(
      decoration: context.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(
            context.tr('total'),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
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
      decoration: context.cardDecoration,
      child: CupertinoTextField(
        controller: _notesCtrl,
        placeholder: context.tr('notes_hint'),
        placeholderStyle: GoogleFonts.poppins(fontSize: 14, color: context.colors.textHint),
        style: GoogleFonts.poppins(fontSize: 14, color: context.colors.textPrimary),
        padding: const EdgeInsets.all(16),
        maxLines: 3,
        minLines: 1,
        decoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }

  // ── Terms & Conditions toggle ──────────────────────────────────────────────
  Widget _buildTermsToggle() {
    final terms = Provider.of<TermsProvider>(context, listen: false);
    if (!terms.hasTerms) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(context, context.tr('terms_conditions')),
        Container(
          decoration: context.cardDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: 16,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('include_on_invoice'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: CupertinoSwitch(
                  value: _includeTerms,
                  activeTrackColor: kPrimary,
                  onChanged: (val) => setState(() => _includeTerms = val),
                ),
              ),
            ],
          ),
        ),
        if (_includeTerms) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: context.cardDecorationFlat,
            padding: const EdgeInsets.all(14),
            child: Text(
              terms.terms,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Bank card ──────────────────────────────────────────────────────────────
  Widget _bankCard() {
    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child:
              _selectedBank != null
                  ? InkWell(
                    onTap: () => _showBankPicker(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.colors.primaryLight,
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
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_selectedBank!.bankName}  •  ${_selectedBank!.accountNumber}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedBank = null),
                            child: Icon(
                              CupertinoIcons.xmark_circle,
                              size: 20,
                              color: context.colors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showBankPicker(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.colors.primaryLight,
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
                            context.tr('add_bank_account'),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: context.colors.textSecondary,
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
  void _showPreview(BuildContext context, ClientProvider client, ItemProvider item, InvoiceProvider invoice) {
    final bp = Provider.of<BusinessProvider>(context, listen: false);
    final tp = Provider.of<TemplatesColorsProvider>(context, listen: false);
    final biz = _selectedBusiness ?? bp.defaultBusiness ?? bp.activeBusiness;

    final previewInvoice = InvoiceModel(
      invoiceId: _isEditMode ? widget.invoice!.invoiceId : invoice.lastId + 1,
      documentType: _documentType,
      businessId: biz?.id,
      businessName: biz?.businessName,
      date: selectDate,
      dueDate: _dueDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      bank: _selectedBank,
      items: item.item
          .map((e) => ItemModel(
                itemName: e.itemName,
                note: e.note,
                price: e.price,
                qty: e.qty,
                id: e.id,
              ))
          .toList(),
      clients: client.client
          .map((e) => ClientModel(
                name: e.name,
                phone: e.phone,
                email: e.email,
                address: e.address,
                id: e.id,
              ))
          .toList(),
    );

    Navigation.go(
      context,
      InvoicePreviewScreen(
        invoice: previewInvoice,
        template: tp.template,
        accentColor: tp.color,
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ClientProvider client,
    ItemProvider item,
    InvoiceProvider invoice,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => _showPreview(context, client, item, invoice),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(CupertinoIcons.eye,
                    size: 18, color: context.colors.textPrimary),
                label: Text(
                  context.tr('preview'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
        txt: _isEditMode
            ? (_documentType == 'Quote'
                ? context.tr('update_quote')
                : _documentType == 'Estimate'
                    ? context.tr('update_estimate')
                    : context.tr('update_invoice'))
            : (_documentType == 'Quote'
                ? context.tr('create_quote')
                : _documentType == 'Estimate'
                    ? context.tr('create_estimate')
                    : context.tr('create_invoice')),
        onTap:
            _isEditMode
                ? () {
                  final tp = Provider.of<TermsProvider>(context, listen: false);
                  invoice.updateInvoiceDetails(
                    widget.invoice!.invoiceId!,
                    date: selectDate,
                    dueDate: _dueDate,
                    notes:
                        _notesCtrl.text.trim().isEmpty
                            ? null
                            : _notesCtrl.text.trim(),
                    termsConditions: _includeTerms ? tp.terms : null,
                    bank: _selectedBank,
                  );
                  client.clearClientFromList();
                  item.item.clear();
                  Navigator.pop(context);
                }
                : () async {
                  final bp = Provider.of<BusinessProvider>(
                    context,
                    listen: false,
                  );
                  final tp = Provider.of<TermsProvider>(context, listen: false);
                  final biz =
                      _selectedBusiness ??
                      bp.defaultBusiness ??
                      bp.activeBusiness;

                  // Only invoices get an invoiceStatus; quotes/estimates do not
                  final isInvoice = _documentType == 'Invoice';

                  await invoice.addInvoice(
                    InvoiceModel(
                      invoiceStatus: isInvoice ? 'UnPaid' : null,
                      documentType: _documentType,
                      businessId: biz?.id,
                      businessName: biz?.businessName ?? 'My Business',
                      date: selectDate,
                      dueDate: _dueDate,
                      invoiceId: invoice.lastId,
                      notes:
                          _notesCtrl.text.trim().isEmpty
                              ? null
                              : _notesCtrl.text.trim(),
                      termsConditions: _includeTerms ? tp.terms : null,
                      bank: _selectedBank,
                      items:
                          item.item
                              .map(
                                (e) => ItemModel(
                                  itemName: e.itemName,
                                  note: e.note,
                                  price: e.price,
                                  qty: e.qty,
                                  id: e.id,
                                  duplicate: e.duplicate,
                                ),
                              )
                              .toList(),
                      clients:
                          client.client
                              .map(
                                (e) => ClientModel(
                                  name: e.name,
                                  phone: e.phone,
                                  email: e.email,
                                  address: e.address,
                                  id: e.id,
                                  duplicate: false,
                                ),
                              )
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
                      clientModel: (latestInvoice.clients?.isNotEmpty ?? false)
                          ? latestInvoice.clients!.first
                          : null,
                      itemModel: (latestInvoice.items?.isNotEmpty ?? false)
                          ? latestInvoice.items!.first
                          : null,
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

class _AddLineItemSheet extends StatefulWidget {
  final List<ServiceModel> services;
  final VoidCallback onNewItem;
  final void Function(List<ServiceModel>) onConfirmServices;

  const _AddLineItemSheet({
    required this.services,
    required this.onNewItem,
    required this.onConfirmServices,
  });

  @override
  State<_AddLineItemSheet> createState() => _AddLineItemSheetState();
}

class _AddLineItemSheetState extends State<_AddLineItemSheet> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final sym = Provider.of<CurrencyProvider>(context, listen: false).symbol;
    final cl = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: cl.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: cl.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('add_item'),
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: cl.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── New custom item row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: widget.onNewItem,
                child: Container(
                  decoration: BoxDecoration(
                    color: cl.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('add_item'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: kPrimary)),
                            Text('Enter name, price & quantity', style: GoogleFonts.poppins(fontSize: 12, color: cl.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_right, size: 14, color: cl.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            // ── Saved services section ───────────────────────────────────────
            if (widget.services.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('services_title').toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: cl.textSecondary, letterSpacing: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                          color: isChosen ? cl.primaryLight : cl.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isChosen ? kPrimary : cl.border, width: isChosen ? 1.5 : 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isChosen ? kPrimary : cl.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (service.name?.isNotEmpty ?? false) ? service.name![0].toUpperCase() : 'S',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: isChosen ? Colors.white : cl.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name ?? '', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: cl.textPrimary)),
                                  if (service.description?.isNotEmpty ?? false)
                                    Text(service.description!, style: GoogleFonts.poppins(fontSize: 12, color: cl.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (service.price != null)
                              Text('$sym${service.price!.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isChosen ? kPrimary : cl.textSecondary)),
                            const SizedBox(width: 8),
                            Icon(
                              isChosen ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                              color: isChosen ? kPrimary : cl.textHint,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppButton(
                  txt: '${context.tr('add')} ${_selected.length} ${context.tr('services_title')}',
                  onTap: () {
                    final chosen = widget.services.where((s) => _selected.contains(s.id)).toList();
                    Navigator.pop(context);
                    widget.onConfirmServices(chosen);
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
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('select_bank_account'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
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
                    Icon(
                      CupertinoIcons.creditcard,
                      size: 40,
                      color: context.colors.textHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('no_bank_accounts'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('go_settings_bank'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.colors.textHint,
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
                          color: isSelected ? context.colors.primaryLight :context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? kPrimary : context.colors.border,
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
                                color: isSelected ? kPrimary : context.colors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.creditcard,
                                color:
                                    isSelected ? Colors.white : context.colors.textSecondary,
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
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${b.bankName}  •  ${b.accountNumber}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: context.colors.textSecondary,
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
                              color: isSelected ? kPrimary : context.colors.textHint,
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
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('select_client'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
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
                    Icon(
                      CupertinoIcons.person_2,
                      size: 40,
                      color: context.colors.textHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('no_saved_clients'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('go_settings_clients'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.colors.textHint,
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
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
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
                                color: context.colors.primaryLight,
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
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  if (c.email?.isNotEmpty ?? false)
                                    Text(
                                      c.email!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: context.colors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else if (c.phone?.isNotEmpty ?? false)
                                    Text(
                                      c.phone!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: context.colors.textSecondary,
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
                txt: context.tr('add_new_client'),
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
