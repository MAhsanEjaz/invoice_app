import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/bank_model.dart';
import 'package:invoicemaker/providers/bank_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:provider/provider.dart';

class AddBankAccountScreen extends StatefulWidget {
  final BankModel? bank;

  const AddBankAccountScreen({super.key, this.bank});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _accountNumberCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  bool _bankNameError = false;
  bool _titleError = false;
  bool _accountNumberError = false;

  bool get _isEdit => widget.bank != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _accountNumberCtrl.text = widget.bank!.accountNumber ?? '';
      _titleCtrl.text = widget.bank!.title ?? '';
      _bankNameCtrl.text = widget.bank!.bankName ?? '';
    }
  }

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _titleCtrl.dispose();
    _bankNameCtrl.dispose();
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
                    sectionLabel(context, context.tr('bank_details')),
                    _buildForm(cl),
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
            _isEdit ? context.tr('edit_bank_account') : context.tr('new_bank_account'),
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
            controller: _bankNameCtrl,
            placeholder: context.tr('bank_name'),
            icon: CupertinoIcons.building_2_fill,
            autofocus: true,
            error: _bankNameError,
            onChanged: () => setState(() => _bankNameError = false),
          ),
          Divider(height: 1, color: cl.border),
          _formField(
            cl: cl,
            controller: _titleCtrl,
            placeholder: context.tr('pdf_account_title'),
            icon: CupertinoIcons.person,
            error: _titleError,
            onChanged: () => setState(() => _titleError = false),
          ),
          Divider(height: 1, color: cl.border),
          _formField(
            cl: cl,
            controller: _accountNumberCtrl,
            placeholder: context.tr('pdf_account_number'),
            icon: CupertinoIcons.number,
            keyboardType: TextInputType.text,
            error: _accountNumberError,
            onChanged: () => setState(() => _accountNumberError = false),
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
                  autofocus: autofocus,
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
      onTap:
          () => customCupertinoDialog(context, () async {
            await Provider.of<BankProvider>(
              context,
              listen: false,
            ).deleteBank(widget.bank!.id!);
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
              context.tr('delete_bank_account_btn'),
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
        txt: _isEdit ? context.tr('update_bank_account') : context.tr('save_bank_account'),
        onTap: () async {
          final bankName = _bankNameCtrl.text.trim();
          final title = _titleCtrl.text.trim();
          final accountNumber = _accountNumberCtrl.text.trim();

          if (bankName.isEmpty || title.isEmpty || accountNumber.isEmpty) {
            setState(() {
              _bankNameError = bankName.isEmpty;
              _titleError = title.isEmpty;
              _accountNumberError = accountNumber.isEmpty;
            });
            return;
          }

          final provider = Provider.of<BankProvider>(context, listen: false);

          if (_isEdit) {
            await provider.updateBank(
              BankModel(
                id: widget.bank!.id,
                bankName: bankName,
                title: title,
                accountNumber: accountNumber,
              ),
            );
          } else {
            await provider.addBank(
              BankModel(
                bankName: bankName,
                title: title,
                accountNumber: accountNumber,
              ),
            );
          }

          if (!mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
