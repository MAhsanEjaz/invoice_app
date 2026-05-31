import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  getBusiness() async {
    final business = Provider.of<BusinessProvider>(context, listen: false);

    await business.getString();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getBusiness();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProvider>(
      builder: (context, business, _) {
        return CupertinoPageScaffold(
          backgroundColor: scaffoldColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoNavigationBar(
                    leading: closeButton(context),
                    padding: EdgeInsetsDirectional.all(0),
                    middle: Text(
                      'Settings',
                      style: TextStyle(color: buttonColor),
                    ),
                  ),

                  customHeight(context, 0.04),

                  Row(
                    children: [
                      Text(business.saveBusinessModel!.businessName.toString()),

                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22.0,
                            vertical: 15,
                          ),
                          child: Text(
                            business
                                .saveBusinessModel!
                                .businessName!
                                .characters
                                .first,
                          ),
                        ),
                      ),
                    ],
                  ),

                  customHeight(context, .03),
                  businessCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  businessCard() {
    return Material(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Manage business'),
              onTap: () {
                Navigation.go(context, BusinessUpatePage());
              },
            ),
            Divider(height: 0, color: Colors.black12),
            ListTile(leading: Icon(Icons.person), title: Text('Clients')),
            Divider(height: 0, color: Colors.black12),

            ListTile(leading: Icon(Icons.pages), title: Text('Items')),
          ],
        ),
      ),
    );
  }
}
