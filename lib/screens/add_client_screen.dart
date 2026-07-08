// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/models/invoice_model.dart';
import 'package:invoicemaker/providers/client_provider.dart';
import 'package:invoicemaker/providers/invoice_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/saved_client_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:invoicemaker/widgets/app_tap.dart';
import 'package:invoicemaker/widgets/app_text_filed.dart';
import 'package:invoicemaker/widgets/responsive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class AddClientScreen extends StatefulWidget {
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final int? id;
  final bool? isPredefined;
  final bool? isDoublePop;
  final List<ClientModel>? client;
  final List<InvoiceModel>? invoice;

  const AddClientScreen({
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
  ClientModel? _matchedClient;
  int fetchId = 0;

  final nameCont = TextEditingController();
  final phoneCont = TextEditingController();
  final emailCont = TextEditingController();
  final addressCont = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    nameCont.dispose();
    phoneCont.dispose();
    emailCont.dispose();
    addressCont.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (widget.name != null) {
      nameCont.text = widget.name!;
      phoneCont.text = widget.phone ?? '';
      emailCont.text = widget.email ?? '';
      addressCont.text = widget.address ?? '';
    }

    if (widget.isPredefined == true) {
      for (var element in widget.invoice ?? []) {
        _matchedClient = (element.clients ?? []).firstWhere(
          (c) => c.name == widget.name,
          orElse: () => ClientModel(),
        );
      }
      _matchedClient = widget.client?.firstWhere(
        (e) => e.name == widget.name,
        orElse: () => ClientModel(),
      );
    } else {
      _matchedClient = widget.client?.firstWhere(
        (e) => e.name == widget.name,
        orElse: () => ClientModel(),
      );
    }

    if (_matchedClient?.id != null) fetchId = _matchedClient!.id!;
  }

  Future<void> _pickContact() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact == null) return;
        nameCont.text = contact.displayName;
        phoneCont.text =
            contact.phones.isNotEmpty ? contact.phones.first.number : '';
        emailCont.text =
            contact.emails.isNotEmpty ? contact.emails.first.address : '';
        addressCont.text =
            contact.addresses.isNotEmpty ? contact.addresses.first.address : '';
        setState(() {});
      } else {
        openAppSettings();
      }
    } catch (err) {
      await Permission.contacts.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return Consumer2<ClientProvider, InvoiceProvider>(
      builder: (context, client, invoice, _) {
        final isEditing = client.name != null;

        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: ResponsiveCenter(
            maxWidth: 640,
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
                        sectionLabel(context, context.tr('client_info')),
                        _buildNameCard(cl),
                        const SizedBox(height: 20),
                        sectionLabel(context, context.tr('contact_details')),
                        _buildContactCard(cl),
                        if (isEditing) ...[
                          const SizedBox(height: 24),
                          _buildDeleteButton(cl, client),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(cl, client, invoice),
              ],
            ),
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
              isEditing ? context.tr('edit_client') : context.tr('new_client'),
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

  Widget _buildNameCard(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          AppTextFiled(
            controller: nameCont,
            placeholder: context.tr('client_name_placeholder'),
            autofocus: true,
          ),
          Divider(height: 1, color: cl.border, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AppTap(
              onTap: _pickContact,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cl.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.contact_phone_outlined,
                      color: kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('import_from_contacts'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: cl.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          AppTextFiled(
            controller: phoneCont,
            placeholder: context.tr('phone'),
            textInputType: TextInputType.phone,
          ),
          Divider(height: 1, color: cl.border, indent: 16, endIndent: 16),
          AppTextFiled(
            controller: emailCont,
            placeholder: context.tr('email'),
            textInputType: TextInputType.emailAddress,
          ),
          Divider(height: 1, color: cl.border, indent: 16, endIndent: 16),
          AppTextFiled(
            controller: addressCont,
            placeholder: context.tr('address'),
            textInputType: TextInputType.streetAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(AppColors cl, ClientProvider client) {
    return AppTap(
      onTap: () {
        customCupertinoDialog(context, () async {
          await client.clearClientFromList();
          if (!mounted) return;
          Navigator.pop(context);
        });
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
              context.tr('remove_from_invoice'),
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
    ClientProvider client,
    InvoiceProvider invoice,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cl.surface,
        border: Border(top: BorderSide(color: cl.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: AppButton(
        onTap: () {
          if (widget.id == null && widget.name == null) {
            final newClient = ClientModel(
              email: emailCont.text.trim(),
              address: addressCont.text.trim(),
              phone: phoneCont.text.trim(),
              name: nameCont.text.trim(),
              duplicate: false,
            );
            client.addClient(newClient);
            Provider.of<SavedClientProvider>(context, listen: false).addClient(
              ClientModel(
                email: newClient.email,
                address: newClient.address,
                phone: newClient.phone,
                name: newClient.name,
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
        txt:
            client.name != null
                ? context.tr('save_changes')
                : context.tr('save_client_btn'),
      ),
    );
  }
}
