import 'enums.dart';

/// A single order line / sale record.
///
/// Monetary fields follow Indian marketplace conventions:
/// - [unitPrice] is the GST-inclusive selling price per unit (what the buyer
///   paid before order-level discounts).
/// - [gstRate] is the GST percentage applicable to the product (e.g. 18.0).
/// - Marketplace [commissionFee], [shippingFee] and [otherFees] are the
///   deductions the platform takes, expressed as positive amounts.
class Sale {
  final int? id;
  final Marketplace marketplace;
  final String orderId;
  final DateTime orderDate;
  final String sku;
  final String productName;
  final int quantity;
  final double unitPrice; // GST-inclusive selling price per unit
  final double discount; // order-level discount (absolute amount)
  final double commissionFee;
  final double shippingFee;
  final double otherFees;
  final double costPrice; // per-unit cost snapshot for profit calc
  final double gstRate; // percentage, e.g. 5, 12, 18
  final bool isInterState; // true => IGST, false => CGST + SGST
  final OrderStatus status;
  final String? buyerState;
  final String? notes;

  /// Actual net amount settled/paid by the marketplace for this line, taken
  /// directly from a settlement report (Flipkart "Bank Settlement Value" /
  /// Amazon settlement). Null when the sale was entered/imported without a
  /// settlement figure, in which case [netSettlement] is used instead.
  final double? settlementValue;

  /// Date the marketplace paid this out (Flipkart "Payment Date"). Used to
  /// group payouts by the month money actually reached your bank.
  final DateTime? settlementDate;

  const Sale({
    this.id,
    required this.marketplace,
    required this.orderId,
    required this.orderDate,
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.commissionFee = 0,
    this.shippingFee = 0,
    this.otherFees = 0,
    this.costPrice = 0,
    this.gstRate = 18,
    this.isInterState = false,
    this.status = OrderStatus.delivered,
    this.buyerState,
    this.notes,
    this.settlementValue,
    this.settlementDate,
  });

  /// Gross amount the buyer paid for this line, after discount, GST inclusive.
  double get grossAmount => (unitPrice * quantity) - discount;

  /// The taxable value (ex-GST) backed out of the GST-inclusive gross amount.
  double get taxableValue => grossAmount / (1 + (gstRate / 100));

  /// Total GST contained in [grossAmount].
  double get gstAmount => grossAmount - taxableValue;

  double get cgst => isInterState ? 0 : gstAmount / 2;
  double get sgst => isInterState ? 0 : gstAmount / 2;
  double get igst => isInterState ? gstAmount : 0;

  double get totalFees => commissionFee + shippingFee + otherFees;

  double get totalCost => costPrice * quantity;

  /// Net profit = ex-GST revenue - product cost - marketplace fees.
  /// GST collected is treated as a pass-through liability, not profit.
  double get netProfit => taxableValue - totalCost - totalFees;

  /// Net settlement you actually receive from the marketplace
  /// (gross minus the fees they deduct).
  double get netSettlement => grossAmount - totalFees;

  /// The amount that actually hits your bank for this line. Prefers the real
  /// settlement figure from a report; otherwise falls back to the computed one.
  double get netPayout => settlementValue ?? netSettlement;

  /// The date to attribute this payout to (settlement date if known).
  DateTime get payoutDate => settlementDate ?? orderDate;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'marketplace': marketplace.name,
      'orderId': orderId,
      'orderDate': orderDate.millisecondsSinceEpoch,
      'sku': sku,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'commissionFee': commissionFee,
      'shippingFee': shippingFee,
      'otherFees': otherFees,
      'costPrice': costPrice,
      'gstRate': gstRate,
      'isInterState': isInterState ? 1 : 0,
      'status': status.name,
      'buyerState': buyerState,
      'notes': notes,
      'settlementValue': settlementValue,
      'settlementDate': settlementDate?.millisecondsSinceEpoch,
    };
  }

  factory Sale.fromMap(Map<String, Object?> map) {
    return Sale(
      id: map['id'] as int?,
      marketplace: Marketplace.fromName(map['marketplace'] as String?),
      orderId: (map['orderId'] as String?) ?? '',
      orderDate: DateTime.fromMillisecondsSinceEpoch(
        (map['orderDate'] as int?) ?? 0,
      ),
      sku: (map['sku'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      commissionFee: (map['commissionFee'] as num?)?.toDouble() ?? 0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0,
      otherFees: (map['otherFees'] as num?)?.toDouble() ?? 0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 18,
      isInterState: ((map['isInterState'] as int?) ?? 0) == 1,
      status: OrderStatus.fromName(map['status'] as String?),
      buyerState: map['buyerState'] as String?,
      notes: map['notes'] as String?,
      settlementValue: (map['settlementValue'] as num?)?.toDouble(),
      settlementDate: map['settlementDate'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['settlementDate'] as int),
    );
  }

  Sale copyWith({
    int? id,
    Marketplace? marketplace,
    String? orderId,
    DateTime? orderDate,
    String? sku,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? commissionFee,
    double? shippingFee,
    double? otherFees,
    double? costPrice,
    double? gstRate,
    bool? isInterState,
    OrderStatus? status,
    String? buyerState,
    String? notes,
    double? settlementValue,
    DateTime? settlementDate,
  }) {
    return Sale(
      id: id ?? this.id,
      marketplace: marketplace ?? this.marketplace,
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      commissionFee: commissionFee ?? this.commissionFee,
      shippingFee: shippingFee ?? this.shippingFee,
      otherFees: otherFees ?? this.otherFees,
      costPrice: costPrice ?? this.costPrice,
      gstRate: gstRate ?? this.gstRate,
      isInterState: isInterState ?? this.isInterState,
      status: status ?? this.status,
      buyerState: buyerState ?? this.buyerState,
      notes: notes ?? this.notes,
      settlementValue: settlementValue ?? this.settlementValue,
      settlementDate: settlementDate ?? this.settlementDate,
    );
  }
}
