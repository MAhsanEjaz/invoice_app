class BusinessModel {
  String id;
  String? businessName;
  String? businessLogo;
  bool isDefault;

  BusinessModel({
    String? id,
    this.businessName,
    this.businessLogo,
    this.isDefault = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'businessLogo': businessLogo,
    'isDefault': isDefault,
  };

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
    id:
        json['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    businessName: json['businessName'] as String?,
    businessLogo: json['businessLogo'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}
