import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/models/business_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessProvider extends ChangeNotifier {
  String? imagePath;

  imagePickFunction() async {
    final imagePath = await ImagePicker.platform.pickImage(
      source: ImageSource.gallery,
    );
    if (imagePath != null) {
      return imagePath.path;
    }

    notifyListeners();
  }

  BusinessProvider() {
    getString();
    getSaveBusinessModel();
  }

  BusinessModel? businessModel;

  BusinessModel? saveBusinessModel;

  getSaveBusinessModel() async {
    final data = await getString();

    saveBusinessModel = data;

    print('saveBusinessModel--->${jsonEncode(saveBusinessModel)}');
  }

  updateBusinessData(String? name) async {

    if(saveBusinessModel == null) return ;

    saveBusinessModel!.businessName = name;
    saveBusinessModel!.businessLogo = imagePath;

    await saveBusiness(jsonEncode(saveBusinessModel!.toJson()));

    print('businessJson--->${jsonEncode(saveBusinessModel!.toJson())}');

    notifyListeners();
  }

  addBusinessData(BusinessModel ourBusiness) {
    businessModel = ourBusiness;

    saveBusiness(jsonEncode(businessModel!.toJson()));

    print('businessName->${jsonEncode(businessModel)}');
    notifyListeners();
  }

  saveBusiness(String? data) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString('business', data!);
  }

  getString() async {
    final prefs = await SharedPreferences.getInstance();

    final myData = prefs.getString('business');

    if (myData != null) {
      Map<String, dynamic> json = jsonDecode(myData);
      return BusinessModel.fromJson(json);
    }
  }
}
