/// The marketplaces this app tracks.
enum Marketplace {
  flipkart,
  amazon;

  String get label {
    switch (this) {
      case Marketplace.flipkart:
        return 'Flipkart';
      case Marketplace.amazon:
        return 'Amazon';
    }
  }

  static Marketplace fromName(String? name) {
    return Marketplace.values.firstWhere(
      (m) => m.name == name,
      orElse: () => Marketplace.flipkart,
    );
  }
}

/// Lifecycle status of an order. Returns/cancellations/refunds are excluded
/// from net revenue and profit calculations.
enum OrderStatus {
  pending,
  shipped,
  delivered,
  returned,
  cancelled,
  refunded;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  /// Whether an order in this status counts as realised revenue.
  bool get countsAsSale {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.shipped:
      case OrderStatus.delivered:
        return true;
      case OrderStatus.returned:
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return false;
    }
  }

  static OrderStatus fromName(String? name) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => OrderStatus.delivered,
    );
  }
}
