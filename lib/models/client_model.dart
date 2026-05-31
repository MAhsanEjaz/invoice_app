class ClientModel {
  int? id;
  String? name;
  String? phone;
  String? email;
  String? address;
  bool? duplicate; // Not nullable now, defaults to false

  ClientModel({
    this.email,
    this.name,
    this.phone,
    this.address,
    this.id,
    this.duplicate, // ✅ Default false
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'id': id,
      'duplicate': duplicate,
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      email: json['email'],
      id: json['id'],
      duplicate: json['duplicate'], // ✅ fallback to false
    );
  }
}
