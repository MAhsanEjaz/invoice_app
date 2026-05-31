import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:invoicemaker/widgets/app_text_filed.dart';
import 'package:provider/provider.dart';

import '../services/navigations.dart';
import 'invoice_dummy.dart' show InvoiceDummy;

class BusinessStartPage extends StatefulWidget {
  const BusinessStartPage({super.key});

  @override
  State<BusinessStartPage> createState() => _BusinessStartPageState();
}

class _BusinessStartPageState extends State<BusinessStartPage> {
  TextEditingController businessCont = TextEditingController();

  bool visibility = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double responsiveFontSize = screenWidth * 0.07; // 4% of screen width

    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        customHeight(context, .04),

                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "What's your\nbusiness name?",
                            style: TextStyle(
                              fontSize: responsiveFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        customHeight(context, .04),
                        AppTextFiled(
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              visibility = true;
                              setState(() {});
                            } else {
                              visibility = false;
                              setState(() {});
                            }
                          },
                          controller: businessCont,
                          placeholder: 'Business Name',
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Our use your own name instead. You can change it later in Setting',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  visibility
                      ? AppButton(
                        txt: 'Continue',
                        onTap: () {
                          business.addBusinessData(
                            BusinessModel(businessName: businessCont.text),
                          );


                          business.getSaveBusinessModel();

                          Navigation.go(context, InvoiceDummy());
                        },
                      )
                      : SizedBox.shrink(),
                  customHeight(context, .03),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
