import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/currency_provider.dart';
import 'package:invoicemaker/providers/service_provider.dart';
import 'package:invoicemaker/screens/add_service_screen.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:provider/provider.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServiceProvider, CurrencyProvider>(
      builder: (context, serviceProvider, currency, _) {
        return CupertinoPageScaffold(
          backgroundColor: kBackground,
          child: SafeArea(
            child: Column(
              children: [
                _buildNavBar(context),
                Expanded(
                  child: serviceProvider.services.isEmpty
                      ? _buildEmpty(context)
                      : _buildList(context, serviceProvider, currency.symbol),
                ),
              ],
            ),
          ),
        );
      },
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
            'Services',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigation.go(context, const AddServiceScreen()),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.add, color: kPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.tag_fill,
              color: kPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add services to quickly apply\nthem when creating invoices.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigation.go(context, const AddServiceScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Add Service',
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
    BuildContext context,
    ServiceProvider provider,
    String currencySymbol,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: provider.services.length,
      itemBuilder: (context, index) {
        final service = provider.services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: kCardDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => Navigation.go(
                    context,
                    AddServiceScreen(service: service),
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
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (service.name?.isNotEmpty ?? false)
                                ? service.name![0].toUpperCase()
                                : 'S',
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
                                service.name ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                              if (service.description?.isNotEmpty ?? false)
                                Text(
                                  service.description!,
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
                        if (service.price != null) ...[
                          Text(
                            '$currencySymbol${service.price!.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
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
          ),
        );
      },
    );
  }
}
