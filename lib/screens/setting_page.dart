import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
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
    return Consumer2<BusinessProvider, CurrencyProvider>(
      builder: (context, business, currency, _) {
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

                        // ── Preferences section ────────────────────────────
                        sectionLabel('Preferences'),
                        _buildPreferencesCard(currency),
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

  // ── Business menu card ─────────────────────────────────────────────────────
  Widget _buildBusinessCard(BusinessProvider business) {
    return Container(
      decoration: kCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              _menuTile(
                icon: CupertinoIcons.building_2_fill,
                label: 'Manage Businesses',
                onTap: () => Navigation.go(
                  context,
                  const ManageBusinessesScreen(),
                ),
              ),
              const Divider(height: 1, color: kBorder),
              _menuTile(
                icon: CupertinoIcons.person_2_fill,
                label: 'Clients',
                onTap: () => Navigation.go(context, const SavedClientsScreen()),
              ),
              const Divider(height: 1, color: kBorder),
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
                onTap: () => Navigation.go(context, const ServicesScreen()),
                isLast: true,
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
