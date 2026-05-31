import 'dart:convert';

class BusinessModel {
  String? businessName;
  String? businessLogo;

  BusinessModel({this.businessName, this.businessLogo});

  Map<String, dynamic> toJson() {
    return {'businessName': businessName, 'businessLogo': businessLogo};
  }

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      businessName: json['businessName'],
      businessLogo: json['businessLogo'],
    );
  }
}
