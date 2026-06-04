class BankModel {
  int? id;
  String? accountNumber;
  String? title;
  String? bankName;

  BankModel({this.id, this.accountNumber, this.title, this.bankName});

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountNumber': accountNumber,
        'title': title,
        'bankName': bankName,
      };

  factory BankModel.fromJson(Map<String, dynamic> json) => BankModel(
        id: json['id'],
        accountNumber: json['accountNumber'],
        title: json['title'],
        bankName: json['bankName'],
      );
}
