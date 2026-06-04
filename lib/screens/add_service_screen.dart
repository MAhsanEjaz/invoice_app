import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/service_model.dart';
import 'package:invoicemaker/providers/service_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';

class AddServiceScreen extends StatefulWidget {
  final ServiceModel? service;

  const AddServiceScreen({super.key, this.service});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.service!.name ?? '';
      _descCtrl.text = widget.service!.description ?? '';
      if (widget.service!.price != null) {
        _priceCtrl.text = widget.service!.price!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
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
                    sectionLabel('Service Details'),
                    _buildForm(),
                    const SizedBox(height: 16),
                    if (_isEdit) _buildDeleteButton(context),
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
            _isEdit ? 'Edit Service' : 'New Service',
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

  Widget _buildForm() {
    return Container(
      decoration: kCardDecoration,
      child: Column(
        children: [
          _formField(
            controller: _nameCtrl,
            placeholder: 'Service name',
            icon: CupertinoIcons.tag,
          ),
          const Divider(height: 1, color: kBorder),
          _formField(
            controller: _descCtrl,
            placeholder: 'Description (optional)',
            icon: CupertinoIcons.doc_text,
          ),
          const Divider(height: 1, color: kBorder),
          _formField(
            controller: _priceCtrl,
            placeholder: 'Default price (optional)',
            icon: CupertinoIcons.money_dollar_circle,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              placeholderStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextHint,
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: kTextPrimary,
              ),
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
        await Provider.of<ServiceProvider>(context, listen: false)
            .deleteService(widget.service!.id!);
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
        ),
        alignment: Alignment.center,
        child: Text(
          'Delete Service',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kDangerColor,
          ),
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
        txt: _isEdit ? 'Update Service' : 'Save Service',
        onTap: () async {
          final name = _nameCtrl.text.trim();
          if (name.isEmpty) return;

          final price = double.tryParse(_priceCtrl.text.trim());
          final desc = _descCtrl.text.trim();
          final provider =
              Provider.of<ServiceProvider>(context, listen: false);

          if (_isEdit) {
            await provider.updateService(ServiceModel(
              id: widget.service!.id,
              name: name,
              description: desc.isEmpty ? null : desc,
              price: price,
            ));
          } else {
            await provider.addService(ServiceModel(
              name: name,
              description: desc.isEmpty ? null : desc,
              price: price,
            ));
          }

          if (!context.mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
