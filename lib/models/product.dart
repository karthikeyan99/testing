/// An inventory item identified by SKU. Used to autofill sale lines and to
/// track stock on hand.
class Product {
  final int? id;
  final String sku;
  final String name;
  final double costPrice; // per-unit purchase cost
  final double gstRate; // default GST percentage for this product
  final int stock; // units on hand
  final int lowStockThreshold;
  final String? hsnCode; // HSN code for GST reporting

  const Product({
    this.id,
    required this.sku,
    required this.name,
    this.costPrice = 0,
    this.gstRate = 18,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.hsnCode,
  });

  bool get isLowStock => stock <= lowStockThreshold;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'costPrice': costPrice,
      'gstRate': gstRate,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'hsnCode': hsnCode,
    };
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      sku: (map['sku'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 18,
      stock: (map['stock'] as int?) ?? 0,
      lowStockThreshold: (map['lowStockThreshold'] as int?) ?? 5,
      hsnCode: map['hsnCode'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? sku,
    String? name,
    double? costPrice,
    double? gstRate,
    int? stock,
    int? lowStockThreshold,
    String? hsnCode,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      gstRate: gstRate ?? this.gstRate,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      hsnCode: hsnCode ?? this.hsnCode,
    );
  }
}
