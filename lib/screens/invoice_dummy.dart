import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/services/navigations.dart';
import 'package:invoicemaker/widgets/app_button.dart';

import 'home_screen.dart';

class InvoiceDummy extends StatefulWidget {
  const InvoiceDummy({super.key});

  @override
  State<InvoiceDummy> createState() => _InvoiceDummyState();
}

class _InvoiceDummyState extends State<InvoiceDummy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              customHeight(context, 0.03),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: closeButton(context)),
              ),
              customHeight(context, 0.05),

              Text(
                'Create invoice\nin a second',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: responseText(context, 0.07),
                ),
              ),
              customHeight(context, 0.05),

              Card(
                elevation: 6,
                child: Image.network(
                  'https://templates.invoicehome.com/invoice-template-en-classic-white-750px.png',
                  height: MediaQuery.sizeOf(context).height * .45,
                ),
              ),
              Spacer(),
              AppButton(
                onTap: () {
                  Navigation.go(context, HomeScreen());
                },
                txt: 'Continue',
              ),
              customHeight(context, 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
