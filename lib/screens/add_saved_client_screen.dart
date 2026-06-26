import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/client_model.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/saved_client_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class AddSavedClientScreen extends StatefulWidget {
  final ClientModel? client;

  const AddSavedClientScreen({super.key, this.client});

  @override
  State<AddSavedClientScreen> createState() => _AddSavedClientScreenState();
}

class _AddSavedClientScreenState extends State<AddSavedClientScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool get _isEdit => widget.client != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.client!.name ?? '';
      _phoneCtrl.text = widget.client!.phone ?? '';
      _emailCtrl.text = widget.client!.email ?? '';
      _addressCtrl.text = widget.client!.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact == null) return;
        setState(() {
          _nameCtrl.text = contact.displayName;
          _phoneCtrl.text =
              contact.phones.isNotEmpty ? contact.phones.first.number : '';
          _emailCtrl.text =
              contact.emails.isNotEmpty ? contact.emails.first.address : '';
          _addressCtrl.text = contact.addresses.isNotEmpty
              ? contact.addresses.first.address
              : '';
        });
      } else {
        openAppSettings();
      }
    } catch (_) {
      await Permission.contacts.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return CupertinoPageScaffold(
      backgroundColor: cl.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildNavBar(cl),
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
                    if (_isEdit) ...[
                      const SizedBox(height: 24),
                      _buildDeleteButton(cl),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomBar(cl),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(AppColors cl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          closeButton(context),
          const Spacer(),
          Text(
            _isEdit ? context.tr('edit_client') : context.tr('new_client'),
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
    );
  }

  Widget _buildNameCard(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          _formField(
            cl: cl,
            controller: _nameCtrl,
            placeholder: context.tr('client_name_placeholder'),
            icon: CupertinoIcons.person,
            autofocus: true,
          ),
          Divider(height: 1, color: cl.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GestureDetector(
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
          _formField(
            cl: cl,
            controller: _phoneCtrl,
            placeholder: context.tr('phone'),
            icon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          Divider(height: 1, color: cl.border),
          _formField(
            cl: cl,
            controller: _emailCtrl,
            placeholder: context.tr('email'),
            icon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          Divider(height: 1, color: cl.border),
          _formField(
            cl: cl,
            controller: _addressCtrl,
            placeholder: context.tr('address'),
            icon: CupertinoIcons.location,
            keyboardType: TextInputType.streetAddress,
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required AppColors cl,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              autofocus: autofocus,
              placeholderStyle:
                  GoogleFonts.poppins(fontSize: 14, color: cl.textHint),
              style:
                  GoogleFonts.poppins(fontSize: 14, color: cl.textPrimary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              keyboardType: keyboardType,
              decoration: const BoxDecoration(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(AppColors cl) {
    return GestureDetector(
      onTap: () => customCupertinoDialog(context, () async {
        await Provider.of<SavedClientProvider>(context, listen: false)
            .deleteClient(widget.client!.id!);
        if (!mounted) return;
        Navigator.of(context)
          ..pop()
          ..pop();
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cl.dangerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDangerColor.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.delete, color: kDangerColor, size: 18),
            const SizedBox(width: 8),
            Text(
              context.tr('delete_client'),
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

  Widget _buildBottomBar(AppColors cl) {
    return Container(
      decoration: BoxDecoration(
        color: cl.surface,
        border: Border(top: BorderSide(color: cl.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: AppButton(
        txt: _isEdit ? context.tr('update_client_btn') : context.tr('save_client_btn'),
        onTap: () async {
          final name = _nameCtrl.text.trim();
          if (name.isEmpty) return;

          final provider =
              Provider.of<SavedClientProvider>(context, listen: false);

          if (_isEdit) {
            await provider.updateClient(ClientModel(
              id: widget.client!.id,
              name: name,
              phone: _phoneCtrl.text.trim().isEmpty
                  ? null
                  : _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim().isEmpty
                  ? null
                  : _emailCtrl.text.trim(),
              address: _addressCtrl.text.trim().isEmpty
                  ? null
                  : _addressCtrl.text.trim(),
            ));
          } else {
            await provider.addClient(ClientModel(
              name: name,
              phone: _phoneCtrl.text.trim().isEmpty
                  ? null
                  : _phoneCtrl.text.trim(),
              email: _emailCtrl.text.trim().isEmpty
                  ? null
                  : _emailCtrl.text.trim(),
              address: _addressCtrl.text.trim().isEmpty
                  ? null
                  : _addressCtrl.text.trim(),
            ));
          }

          if (!mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
