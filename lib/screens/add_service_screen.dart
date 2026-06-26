import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/service_model.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
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

  bool _nameError = false;
  bool _priceError = false;

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
                    sectionLabel(context, context.tr('service_details')),
                    _buildForm(cl),
                    const SizedBox(height: 16),
                    if (_isEdit) _buildDeleteButton(cl),
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
            _isEdit ? context.tr('edit_service') : context.tr('new_service'),
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

  Widget _buildForm(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: Column(
        children: [
          _formField(
            cl: cl,
            controller: _nameCtrl,
            placeholder: context.tr('service_name_placeholder'),
            icon: CupertinoIcons.tag,
            error: _nameError,
            onChanged: () => setState(() => _nameError = false),
          ),
          Divider(height: 1, color: cl.border),
          _formField(
            cl: cl,
            controller: _descCtrl,
            placeholder: context.tr('notes_optional'),
            icon: CupertinoIcons.doc_text,
          ),
          Divider(height: 1, color: cl.border),
          _formField(
            cl: cl,
            controller: _priceCtrl,
            placeholder: context.tr('price'),
            icon: CupertinoIcons.money_dollar_circle,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            error: _priceError,
            onChanged: () => setState(() => _priceError = false),
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
    bool error = false,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: error ? 8 : 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: error ? kDangerColor : kPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  placeholderStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: error ? kDangerColor.withValues(alpha: 0.6) : cl.textHint,
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: cl.textPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  keyboardType: keyboardType,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  onChanged: onChanged != null ? (_) => onChanged() : null,
                ),
                if (error)
                  Text(
                    context.tr('required_field'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: kDangerColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(AppColors cl) {
    return GestureDetector(
      onTap: () => customCupertinoDialog(context, () async {
        await Provider.of<ServiceProvider>(context, listen: false)
            .deleteService(widget.service!.id!);
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
        ),
        alignment: Alignment.center,
        child: Text(
          context.tr('delete_service'),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kDangerColor,
          ),
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
        txt: _isEdit ? context.tr('update_service') : context.tr('save_service'),
        onTap: () async {
          final name = _nameCtrl.text.trim();
          final price = double.tryParse(_priceCtrl.text.trim());

          if (name.isEmpty || price == null) {
            setState(() {
              _nameError = name.isEmpty;
              _priceError = price == null;
            });
            return;
          }

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

          if (!mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
