class ItemModel {
  int? id;
  String? itemName;
  String? note;
  num? price;
  int? qty;

  bool? duplicate;

  ItemModel({
    this.qty,
    this.price,
    this.itemName,
    this.note,
    this.id,
    this.duplicate,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'note': note,
      'price': price,
      'qty': qty ?? 1,
      'id': id ?? 0,
      'duplicate': duplicate,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      itemName: json['itemName'],
      duplicate: json['duplicate'] ,
      price: json['price'],
      qty: json['qty'] ?? 1,
      note: json['note'],
      id: json['id'] ?? 0,
    );
  }
}
