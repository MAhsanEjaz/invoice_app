class ServiceModel {
  int? id;
  String? name;
  String? description;
  num? price;

  ServiceModel({this.id, this.name, this.description, this.price});

  Map<String, dynamic> toJson() => {
        'id': id ?? 0,
        'name': name,
        'description': description,
        'price': price,
      };

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] ?? 0,
        name: json['name'],
        description: json['description'],
        price: json['price'],
      );
}
