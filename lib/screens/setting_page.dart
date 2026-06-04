import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/terms_provider.dart';
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
    return Consumer3<BusinessProvider, CurrencyProvider, TermsProvider>(
      builder: (context, business, currency, terms, _) {
        final name = business.activeBusiness?.businessName ?? '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return CupertinoPageScaffold(
          backgroundColor: kBackground,
          child: SafeArea(
            child: Column(
              children: [
                _buildNavBar(),
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
                        _buildBusinessHeader(name, initial, business.businesses.length),
                        const SizedBox(height: 24),

                        // ── Business section ───────────────────────────────
                        sectionLabel('Business'),
                        _buildBusinessCard(business),
                        const SizedBox(height: 24),

                        // ── Shared data section ────────────────────────────
                        sectionLabel('Shared'),
                        _buildSharedDataCard(),
                        const SizedBox(height: 24),

                        // ── Preferences section ────────────────────────────
                        sectionLabel('Preferences'),
                        _buildPreferencesCard(currency),
                        const SizedBox(height: 24),

                        // ── Invoice Defaults section ───────────────────────
                        sectionLabel('Invoice Defaults'),
                        _buildTermsCard(terms),
                        const SizedBox(height: 32),

                        Center(
                          child: Text(
                            'Invoice Maker v1.0.0',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: kTextHint,
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

  // ── Nav bar ────────────────────────────────────────────────────────────────
  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          closeButton(context),
          const Spacer(),
          Text(
            'Settings',
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

  // ── Business header card ───────────────────────────────────────────────────
  Widget _buildBusinessHeader(String name, String initial, int businessCount) {
    return Container(
      decoration: kCardDecoration,
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
                    color: kTextPrimary,
                  ),
                ),
                Text(
                  businessCount > 1
                      ? '$businessCount businesses'
                      : 'Your Business',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Business menu card (business-specific settings only) ──────────────────
  Widget _buildBusinessCard(BusinessProvider business) {
    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: _menuTile(
            icon: CupertinoIcons.building_2_fill,
            label: 'Manage Businesses',
            isLast: true,
            onTap: () => Navigation.go(context, const ManageBusinessesScreen()),
          ),
        ),
      ),
    );
  }

  // ── Shared data card (common across all businesses) ────────────────────────
  Widget _buildSharedDataCard() {
    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              _menuTile(
                icon: CupertinoIcons.person_2_fill,
                label: 'Clients',
                onTap: () => Navigation.go(context, const SavedClientsScreen()),
              ),
              const Divider(height: 1, color: kBorder),
              _menuTile(
                icon: CupertinoIcons.creditcard_fill,
                label: 'Bank Accounts',
                onTap: () => Navigation.go(context, const BankAccountsScreen()),
              ),
              const Divider(height: 1, color: kBorder),
              _menuTile(
                icon: CupertinoIcons.tag_fill,
                label: 'Items & Services',
                isLast: true,
                onTap: () => Navigation.go(context, const ServicesScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Preferences card (currency + future prefs) ─────────────────────────────
  Widget _buildPreferencesCard(CurrencyProvider currency) {
    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => Navigation.go(context, const CurrencyScreen()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.globe,
                      color: kPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Label
                  Expanded(
                    child: Text(
                      'Currency',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kTextPrimary,
                      ),
                    ),
                  ),

                  // Current selection badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
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
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: kTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Terms & Conditions card ────────────────────────────────────────────────
  Widget _buildTermsCard(TermsProvider terms) {
    final hasTerms = terms.hasTerms;
    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _showTermsEditor(terms),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          'Terms & Conditions',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: kTextPrimary,
                          ),
                        ),
                        Text(
                          hasTerms ? terms.terms : 'Not set — tap to add',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: kTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsEditor(TermsProvider terms) {
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
          decoration: const BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Terms & Conditions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shown on invoices when you choose to include them.',
                style: GoogleFonts.poppins(fontSize: 12, color: kTextSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: kCardDecoration,
                child: CupertinoTextField(
                  controller: ctrl,
                  placeholder: 'e.g. Payment due within 30 days…',
                  placeholderStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: kTextHint,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: kTextPrimary,
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
                        side: BorderSide(color: kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: kTextSecondary,
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
                        'Save',
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

  // ── Reusable menu tile ─────────────────────────────────────────────────────
  Widget _menuTile({
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
                color: kPrimaryLight,
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
                  color: kTextPrimary,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
