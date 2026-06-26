import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/models/currency_model.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<CurrencyModel> _filtered = CurrencyModel.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? CurrencyModel.all
          : CurrencyModel.all
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.code.toLowerCase().contains(q) ||
                  c.symbol.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, _) {
        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(children: [
                    closeButton(context),
                    const Spacer(),
                    Text(context.tr('currency'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: cl.textPrimary)),
                    const Spacer(),
                    const SizedBox(width: 34),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: CupertinoTextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  placeholder: context.tr('search_currency'),
                  placeholderStyle: GoogleFonts.poppins(fontSize: 14, color: cl.textHint),
                  style: GoogleFonts.poppins(fontSize: 14, color: cl.textPrimary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(CupertinoIcons.search, size: 18, color: cl.textSecondary),
                  ),
                  clearButtonMode: OverlayVisibilityMode.editing,
                  decoration: BoxDecoration(
                    color: cl.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cl.border),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cl.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Text(currencyProvider.currency.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${context.tr('currency_current_prefix')}${currencyProvider.currency.name} (${currencyProvider.code})',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: kPrimary),
                      ),
                    ),
                    Text(currencyProvider.symbol, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: kPrimary)),
                  ]),
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(child: Text('${context.tr('no_results_for')}"${_searchCtrl.text}"',
                        style: GoogleFonts.poppins(fontSize: 14, color: cl.textSecondary)))
                    : Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: context.cardDecoration,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            type: MaterialType.transparency,
                            child: ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: cl.border),
                              itemBuilder: (context, index) {
                                final c = _filtered[index];
                                final isSelected = c.code == currencyProvider.code;
                                return InkWell(
                                  onTap: () {
                                    currencyProvider.select(c);
                                    Navigator.pop(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(children: [
                                      Text(c.flag, style: const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 14),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(c.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: cl.textPrimary)),
                                        Text(c.code, style: GoogleFonts.poppins(fontSize: 12, color: cl.textSecondary)),
                                      ])),
                                      Text(c.symbol, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? kPrimary : cl.textSecondary)),
                                      const SizedBox(width: 10),
                                      AnimatedOpacity(
                                        opacity: isSelected ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: const Icon(CupertinoIcons.checkmark_alt, size: 18, color: kPrimary),
                                      ),
                                    ]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
