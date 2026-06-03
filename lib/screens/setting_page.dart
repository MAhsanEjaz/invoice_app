import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';

import 'business_upate_page.dart';

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
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        final name = business.saveBusinessModel?.businessName ?? '';
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
                        _buildBusinessHeader(name, initial),
                        const SizedBox(height: 24),
                        sectionLabel('Business'),
                        _buildMenuCard(business),
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

  Widget _buildBusinessHeader(String name, String initial) {
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
                  'Your Business',
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

  Widget _buildMenuCard(BusinessProvider business) {
    return Container(
      decoration: kCardDecoration,
      // ClipRRect clips the ink ripple to the card shape;
      // Material(transparency) provides the Material ancestor InkWell needs
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              _menuTile(
                icon: CupertinoIcons.building_2_fill,
                label: 'Manage Business',
                onTap: () => Navigation.go(context, BusinessUpatePage()),
              ),
              const Divider(height: 1, color: kBorder),
              _menuTile(
                icon: CupertinoIcons.person_2_fill,
                label: 'Clients',
                onTap: () {},
              ),
              const Divider(height: 1, color: kBorder),
              _menuTile(
                icon: CupertinoIcons.tag_fill,
                label: 'Items & Services',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
