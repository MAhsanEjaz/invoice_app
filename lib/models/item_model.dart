class ItemModel {
  int? id;
  String? itemName;
  String? note;
  num? price;
  int? qty;
  bool? duplicate;
  // Per-line discount: amount or percentage depending on discountType
  double? discount;
  // 'flat' = absolute amount | 'percent' = percentage of line gross
  String? discountType;

  ItemModel({
    this.qty,
    this.price,
    this.itemName,
    this.note,
    this.id,
    this.duplicate,
    this.discount,
    this.discountType,
  });

  /// Gross before item-level discount.
  double get gross => (price?.toDouble() ?? 0) * (qty ?? 1);

  /// Net line total after item-level discount, clamped to 0.
  double get lineTotal {
    final g = gross;
    final d = discount ?? 0;
    if (d <= 0) return g;
    if (discountType == 'percent') return (g * (1 - d / 100)).clamp(0.0, double.infinity);
    return (g - d).clamp(0.0, double.infinity);
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'note': note,
      'price': price,
      'qty': qty ?? 1,
      'id': id ?? 0,
      'duplicate': duplicate,
      'discount': discount,
      'discountType': discountType,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      itemName: json['itemName'],
      duplicate: json['duplicate'],
      price: json['price'],
      qty: json['qty'] ?? 1,
      note: json['note'],
      id: json['id'] ?? 0,
      discount: (json['discount'] as num?)?.toDouble(),
      discountType: json['discountType'] as String?,
    );
  }
}
