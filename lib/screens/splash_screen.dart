import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../services/navigations.dart' show Navigation;
import 'business_start_page.dart';
import 'items_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  splashNav() async {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );

    final data =await businessProvider.getString();

    print('jsonBusinessData-->${jsonEncode(data)}');

    if ( data!=null ) {
      Timer(Duration(seconds: 3), () {
        Navigation.clearAll(context, HomeScreen());
      });
    } else {
      Timer(Duration(seconds: 3), () {
        Navigation.clearAll(context, BusinessStartPage());
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    splashNav();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: scaffoldColor,
      child: Center(
        child: Text(
              'Invoice Maker',
              style: TextStyle(
                fontSize: responseText(context, 0.08),
                fontWeight: FontWeight.bold,
              ),
            )
            .animate()
            .tint(color: buttonColor)
            .then()
            .shake(delay: Duration(seconds: 1)),
      ),
    );
  }
}
