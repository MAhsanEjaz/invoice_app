import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/bank_model.dart';
import 'package:invoicemaker/providers/bank_provider.dart';
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
                    sectionLabel('Bank Details'),
                    _buildForm(),
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
            _isEdit ? 'Edit Bank Account' : 'New Bank Account',
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
            controller: _bankNameCtrl,
            placeholder: 'Bank Name',
            icon: CupertinoIcons.building_2_fill,
            autofocus: true,
          ),
          const Divider(height: 1, color: kBorder),
          _formField(
            controller: _titleCtrl,
            placeholder: 'Account Title',
            icon: CupertinoIcons.person,
          ),
          const Divider(height: 1, color: kBorder),
          _formField(
            controller: _accountNumberCtrl,
            placeholder: 'Account Number',
            icon: CupertinoIcons.number,
            keyboardType: TextInputType.text,
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
        await Provider.of<BankProvider>(context, listen: false)
            .deleteBank(widget.bank!.id!);
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
              'Delete Bank Account',
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
        txt: _isEdit ? 'Update Bank Account' : 'Save Bank Account',
        onTap: () async {
          final bankName = _bankNameCtrl.text.trim();
          final title = _titleCtrl.text.trim();
          final accountNumber = _accountNumberCtrl.text.trim();

          if (bankName.isEmpty || title.isEmpty || accountNumber.isEmpty) return;

          final provider = Provider.of<BankProvider>(context, listen: false);

          if (_isEdit) {
            await provider.updateBank(BankModel(
              id: widget.bank!.id,
              bankName: bankName,
              title: title,
              accountNumber: accountNumber,
            ));
          } else {
            await provider.addBank(BankModel(
              bankName: bankName,
              title: title,
              accountNumber: accountNumber,
            ));
          }

          if (!context.mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}
