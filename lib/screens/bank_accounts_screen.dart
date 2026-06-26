import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/providers/bank_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/screens/add_bank_account_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';

class BankAccountsScreen extends StatelessWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return Consumer<BankProvider>(
      builder: (context, provider, _) {
        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: SafeArea(
            child: Column(
              children: [
                _buildNavBar(context, cl),
                Expanded(
                  child: provider.banks.isEmpty
                      ? _buildEmpty(context, cl)
                      : _buildList(context, cl, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBar(BuildContext context, AppColors cl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          closeButton(context),
          const Spacer(),
          Text(
            context.tr('bank_accounts'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cl.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigation.go(context, const AddBankAccountScreen()),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cl.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.add, color: kPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppColors cl) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cl.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.creditcard_fill,
              color: kPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_bank_accounts_yet'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cl.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('no_bank_accounts_msg'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: cl.textSecondary),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () =>
                Navigation.go(context, const AddBankAccountScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.tr('add_bank_account'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, AppColors cl, BankProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: provider.banks.length,
      itemBuilder: (context, index) {
        final bank = provider.banks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: context.cardDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => Navigation.go(
                    context,
                    AddBankAccountScreen(bank: bank),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: cl.primaryLight,
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
                                bank.title ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cl.textPrimary,
                                ),
                              ),
                              Text(
                                bank.bankName ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: cl.textSecondary,
                                ),
                              ),
                              Text(
                                bank.accountNumber ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: cl.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 14,
                          color: cl.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
