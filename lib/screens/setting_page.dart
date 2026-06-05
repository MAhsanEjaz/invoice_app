import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/terms_provider.dart';
import 'package:invoicemaker/providers/theme_provider.dart';
import 'package:invoicemaker/screens/currency_screen.dart';
import 'package:invoicemaker/screens/services_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';

import 'bank_accounts_screen.dart';
import 'manage_businesses_screen.dart';
import 'saved_clients_screen.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusinessProvider>(context, listen: false).getString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.colors;
    return Consumer4<BusinessProvider, CurrencyProvider, TermsProvider,
        ThemeProvider>(
      builder: (context, business, currency, terms, themeProvider, _) {
        final name = business.activeBusiness?.businessName ?? '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                        const SizedBox(height: 8),
                        _buildBusinessHeader(cl, name, initial,
                            business.businesses.length),
                        const SizedBox(height: 24),

                        sectionLabel(context, context.tr('business')),
                        _buildBusinessCard(cl),
                        const SizedBox(height: 24),

                        sectionLabel(context, context.tr('shared')),
                        _buildSharedDataCard(cl),
                        const SizedBox(height: 24),

                        sectionLabel(context, context.tr('preferences')),
                        _buildPreferencesCard(cl, currency),
                        const SizedBox(height: 24),

                        sectionLabel(context, context.tr('appearance')),
                        _buildAppearanceCard(cl, themeProvider),
                        const SizedBox(height: 24),

                        sectionLabel(context, context.tr('language')),
                        _buildLanguageCard(cl),
                        const SizedBox(height: 24),

                        sectionLabel(context, context.tr('invoice_defaults')),
                        _buildTermsCard(cl, terms),
                        const SizedBox(height: 32),

                        Center(
                          child: Text(
                            'Invoice Maker v1.0.0',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: cl.textHint,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            context.tr('settings'),
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

  Widget _buildBusinessHeader(
      AppColors cl, String name, String initial, int businessCount) {
    return Container(
      decoration: context.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: cl.textPrimary,
                  ),
                ),
                Text(
                  businessCount > 1
                      ? '$businessCount ${context.tr('businesses')}'
                      : context.tr('your_business'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: cl.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: _menuTile(
            cl: cl,
            icon: CupertinoIcons.building_2_fill,
            label: context.tr('manage_businesses'),
            isLast: true,
            onTap: () => Navigation.go(context, const ManageBusinessesScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildSharedDataCard(AppColors cl) {
    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              _menuTile(
                cl: cl,
                icon: CupertinoIcons.person_2_fill,
                label: context.tr('clients'),
                onTap: () =>
                    Navigation.go(context, const SavedClientsScreen()),
              ),
              Divider(height: 1, color: cl.border),
              _menuTile(
                cl: cl,
                icon: CupertinoIcons.creditcard_fill,
                label: context.tr('bank_accounts'),
                onTap: () =>
                    Navigation.go(context, const BankAccountsScreen()),
              ),
              Divider(height: 1, color: cl.border),
              _menuTile(
                cl: cl,
                icon: CupertinoIcons.tag_fill,
                label: context.tr('items_services'),
                isLast: true,
                onTap: () => Navigation.go(context, const ServicesScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(AppColors cl, CurrencyProvider currency) {
    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => Navigation.go(context, const CurrencyScreen()),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      CupertinoIcons.globe,
                      color: kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.tr('currency'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cl.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cl.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${currency.currency.flag}  '
                      '${currency.code}  ${currency.symbol}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
    );
  }

  Widget _buildAppearanceCard(AppColors cl, ThemeProvider themeProvider) {
    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cl.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDark
                        ? CupertinoIcons.moon_fill
                        : CupertinoIcons.sun_max_fill,
                    color: kPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.tr('dark_mode'),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cl.textPrimary,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: CupertinoSwitch(
                    value: themeProvider.isDark,
                    activeTrackColor: kPrimary,
                    onChanged: themeProvider.setDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(AppColors cl) {
    final localeProvider = context.watch<LocaleProvider>();
    final current = localeProvider.languageCode;

    final languages = [
      ('en', context.tr('english'), '🇬🇧'),
      ('ur', context.tr('urdu'), '🇵🇰'),
      ('hi', context.tr('hindi'), '🇮🇳'),
    ];

    final currentLabel = languages
        .firstWhere((l) => l.$1 == current, orElse: () => languages.first)
        .$2;

    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _showLanguagePicker(cl, localeProvider, languages),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      CupertinoIcons.textformat_abc,
                      color: kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.tr('language'),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cl.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cl.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
    );
  }

  void _showLanguagePicker(
    AppColors cl,
    LocaleProvider localeProvider,
    List<(String, String, String)> languages,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cl.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cl.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              context.tr('language'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cl.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = localeProvider.languageCode == lang.$1;
              return GestureDetector(
                onTap: () {
                  localeProvider.setLocale(lang.$1);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? cl.primaryLight : cl.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? kPrimary : cl.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang.$3,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          lang.$2,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: cl.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(CupertinoIcons.checkmark_circle_fill,
                            color: kPrimary, size: 20)
                      else
                        Icon(CupertinoIcons.circle,
                            color: cl.textHint, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard(AppColors cl, TermsProvider terms) {
    final hasTerms = terms.hasTerms;
    return Container(
      decoration: context.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _showTermsEditor(cl, terms),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      CupertinoIcons.doc_text,
                      color: kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('terms_conditions'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: cl.textPrimary,
                          ),
                        ),
                        Text(
                          hasTerms
                              ? terms.terms
                              : context.tr('not_set_tap'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: cl.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
    );
  }

  void _showTermsEditor(AppColors cl, TermsProvider terms) {
    final ctrl = TextEditingController(text: terms.terms);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cl.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cl.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                context.tr('terms_conditions'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cl.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('terms_hint'),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: cl.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: context.cardDecoration,
                child: CupertinoTextField(
                  controller: ctrl,
                  placeholder: 'e.g. Payment due within 30 days…',
                  placeholderStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: cl.textHint,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: cl.textPrimary,
                  ),
                  padding: const EdgeInsets.all(14),
                  maxLines: 6,
                  minLines: 4,
                  decoration: const BoxDecoration(color: Colors.transparent),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ctrl.clear();
                        terms.save('');
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cl.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        context.tr('clear'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: cl.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        terms.save(ctrl.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        context.tr('save'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required AppColors cl,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cl.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kPrimary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cl.textPrimary,
                ),
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
    );
  }
}
