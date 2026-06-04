import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/client_model.dart';
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
          _addressCtrl.text =
              contact.addresses.isNotEmpty
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
    return CupertinoPageScaffold(
      backgroundColor: kBackground,
      child: SafeArea(
        child: Column(
          children: [
            _buildNavBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionLabel('Client Info'),
                    _buildNameCard(),
                    const SizedBox(height: 20),
                    sectionLabel('Contact Details'),
                    _buildContactCard(),
                    if (_isEdit) ...[
                      const SizedBox(height: 24),
                      _buildDeleteButton(context),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          closeButton(context),
          const Spacer(),
          Text(
            _isEdit ? 'Edit Client' : 'New Client',
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
    );
  }

  Widget _buildNameCard() {
    return Container(
      decoration: kCardDecoration,
      child: Column(
        children: [
          _formField(
            controller: _nameCtrl,
            placeholder: 'Client Name',
            icon: CupertinoIcons.person,
            autofocus: true,
          ),
          const Divider(height: 1, color: kBorder),
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
                      color: kPrimaryLight,
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
                    'Import from contacts',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: kTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: kCardDecoration,
      child: Column(
        children: [
          _formField(
            controller: _phoneCtrl,
            placeholder: 'Phone',
            icon: CupertinoIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          const Divider(height: 1, color: kBorder),
          _formField(
            controller: _emailCtrl,
            placeholder: 'Email',
            icon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
          ),
          const Divider(height: 1, color: kBorder),
          _formField(
            controller: _addressCtrl,
            placeholder: 'Address',
            icon: CupertinoIcons.location,
            keyboardType: TextInputType.streetAddress,
          ),
        ],
      ),
    );
  }

  Widget _formField({
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
              placeholderStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextHint,
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              keyboardType: keyboardType,
              decoration: const BoxDecoration(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => customCupertinoDialog(context, () async {
        await Provider.of<SavedClientProvider>(context, listen: false)
            .deleteClient(widget.client!.id!);
        if (!context.mounted) return;
        Navigator.of(context)
          ..pop()
          ..pop();
      }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kDangerBg,
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
              'Delete Client',
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

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: AppButton(
        txt: _isEdit ? 'Update Client' : 'Save Client',
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

          if (!context.mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
