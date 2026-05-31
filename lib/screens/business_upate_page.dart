import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/widgets/app_button.dart';
import 'package:invoicemaker/widgets/app_text_filed.dart';
import 'package:provider/provider.dart';

class BusinessUpatePage extends StatefulWidget {
  const BusinessUpatePage({super.key});

  @override
  State<BusinessUpatePage> createState() => _BusinessUpatePageState();
}

class _BusinessUpatePageState extends State<BusinessUpatePage> {
  TextEditingController businessCont = TextEditingController();

  getBusinessData() {
    final provider = Provider.of<BusinessProvider>(context, listen: false);

    businessCont.text = provider.saveBusinessModel!.businessName!;
    provider.imagePath = provider.saveBusinessModel!.businessLogo ?? '';

    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getBusinessData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return CupertinoPageScaffold(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoNavigationBar(
                  leading: closeButton(context),
                  middle: Text('Manage Business'),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      customHeight(context, 0.03),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Material(
                          surfaceTintColor: Colors.transparent,
                          color: CupertinoColors.white,
                          child: InkWell(
                            onTap: () async {
                              business.imagePath =
                                  await business.imagePickFunction();
                              setState(() {});
                            },
                            child: Container(
                              height: 200,
                              width: 200,
                              color: Colors.grey.shade200,
                              child:
                                  business.imagePath != null
                                      ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Blurred background
                                          Positioned.fill(
                                            child: Image.file(
                                              File(business.imagePath!),
                                              fit:
                                                  BoxFit
                                                      .cover, // Show full image
                                            ),
                                          ),
                                        ],
                                      )
                                      : const Icon(Icons.add_a_photo, size: 50),
                            ),
                          ),
                        ),
                      ),

                      customHeight(context, 0.03),
                      AppTextFiled(controller: businessCont),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppButton(
                  onTap: () {
                    business.updateBusinessData(businessCont.text);
                  },
                  txt: 'Update Business',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
