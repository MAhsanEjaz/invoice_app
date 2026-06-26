import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:invoicemaker/providers/locale_provider.dart';
import 'package:invoicemaker/providers/saved_client_provider.dart';
import 'package:invoicemaker/screens/add_saved_client_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';

class SavedClientsScreen extends StatelessWidget {
  const SavedClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final cl = context.colors;
    return Consumer<SavedClientProvider>(
      builder: (context, provider, _) {
        return CupertinoPageScaffold(
          backgroundColor: cl.background,
          child: SafeArea(
            child: Column(
              children: [
                _buildNavBar(context, cl),
                Expanded(
                  child: provider.clients.isEmpty
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
            context.tr('clients'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cl.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigation.go(context, const AddSavedClientScreen()),
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
              CupertinoIcons.person_2_fill,
              color: kPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_clients_yet'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cl.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('no_clients_msg'),
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 14, color: cl.textSecondary),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigation.go(context, const AddSavedClientScreen()),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.tr('add_client'),
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
      BuildContext context, AppColors cl, SavedClientProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: provider.clients.length,
      itemBuilder: (context, index) {
        final client = provider.clients[index];
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
                    AddSavedClientScreen(client: client),
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
                          alignment: Alignment.center,
                          child: Text(
                            (client.name?.isNotEmpty ?? false)
                                ? client.name![0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cl.textPrimary,
                                ),
                              ),
                              if (client.email?.isNotEmpty ?? false)
                                Text(
                                  client.email!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: cl.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else if (client.phone?.isNotEmpty ?? false)
                                Text(
                                  client.phone!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: cl.textSecondary,
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
