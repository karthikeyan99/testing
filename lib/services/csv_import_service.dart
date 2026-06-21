import 'package:csv/csv.dart';

import '../models/enums.dart';
import '../models/sale.dart';

/// Result of a CSV import attempt.
class ImportResult {
  final List<Sale> sales;
  final int skipped;
  final List<String> warnings;

  const ImportResult({
    required this.sales,
    this.skipped = 0,
    this.warnings = const [],
  });
}

/// Parses order/sales report CSVs exported from Flipkart Seller Hub and
/// Amazon Seller Central into [Sale] records.
///
/// Marketplaces change their column headers occasionally, so matching is done
/// by a set of candidate header names (case/space/underscore-insensitive)
/// rather than fixed positions. Unknown columns are ignored.
class CsvImportService {
  /// Parses raw CSV text into [Sale] records for the given [marketplace].
  ImportResult importString(String raw, Marketplace marketplace) {
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(raw.replaceAll('\r\n', '\n'));

    if (rows.isEmpty) {
      return const ImportResult(sales: [], warnings: ['File is empty']);
    }

    final header = rows.first.map((c) => _norm(c.toString())).toList();
    int idx(List<String> candidates) {
      for (final c in candidates) {
        final i = header.indexOf(_norm(c));
        if (i != -1) return i;
      }
      return -1;
    }

    final col = marketplace == Marketplace.flipkart
        ? _flipkartColumns(idx)
        : _amazonColumns(idx);

    final warnings = <String>[];
    if (col.orderId == -1) {
      warnings.add('Could not find an Order ID column.');
    }

    final sales = <Sale>[];
    var skipped = 0;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      String cell(int i) =>
          (i >= 0 && i < row.length) ? row[i].toString().trim() : '';

      final orderId = cell(col.orderId);
      final sku = cell(col.sku);
      if (orderId.isEmpty && sku.isEmpty) {
        skipped++;
        continue;
      }

      final qty = _toInt(cell(col.quantity), fallback: 1);
      final unitPrice = _toDouble(cell(col.unitPrice));

      sales.add(
        Sale(
          marketplace: marketplace,
          orderId: orderId.isEmpty ? 'UNKNOWN-$r' : orderId,
          orderDate: _toDate(cell(col.orderDate)),
          sku: sku,
          productName: cell(col.productName),
          quantity: qty,
          unitPrice: unitPrice,
          discount: _toDouble(cell(col.discount)),
          commissionFee: _toDouble(cell(col.commissionFee)),
          shippingFee: _toDouble(cell(col.shippingFee)),
          otherFees: _toDouble(cell(col.otherFees)),
          gstRate: col.gstRate == -1
              ? 18
              : _toDouble(cell(col.gstRate), fallback: 18),
          status: _mapStatus(cell(col.status)),
          buyerState: col.buyerState == -1 ? null : cell(col.buyerState),
        ),
      );
    }

    return ImportResult(sales: sales, skipped: skipped, warnings: warnings);
  }

  _ColumnMap _flipkartColumns(int Function(List<String>) idx) {
    return _ColumnMap(
      orderId: idx(['Order Id', 'Order ID', 'Order Item Id']),
      orderDate: idx(['Ordered On', 'Order Date', 'Order Approval Date']),
      sku: idx(['SKU', 'SKU Id', 'Seller SKU']),
      productName: idx(['Product', 'Product Title', 'Item Name']),
      quantity: idx(['Quantity', 'Item Quantity', 'Qty']),
      unitPrice: idx(['Selling Price Per Item', 'Final Selling Price', 'Price']),
      discount: idx(['Total Discount', 'Discount']),
      commissionFee: idx(['Commission', 'Marketplace Fee', 'Commission Fee']),
      shippingFee: idx(['Shipping Fee', 'Shipping Charges', 'Logistics Fee']),
      otherFees: idx(['Collection Fee', 'Fixed Fee', 'Other Fees']),
      gstRate: idx(['GST Rate', 'Tax Rate', 'GST %']),
      status: idx(['Order Status', 'Status', 'Event Type']),
      buyerState: idx(['Buyer State', 'Customer State', 'State']),
    );
  }

  _ColumnMap _amazonColumns(int Function(List<String>) idx) {
    return _ColumnMap(
      orderId: idx(['amazon-order-id', 'Order ID', 'Order Id']),
      orderDate: idx(['purchase-date', 'Order Date', 'payments-date']),
      sku: idx(['sku', 'seller-sku', 'SKU']),
      productName: idx(['product-name', 'item-name', 'Title']),
      quantity: idx(['quantity', 'quantity-purchased', 'Qty']),
      unitPrice: idx(['item-price', 'product sales', 'price']),
      discount: idx(['item-promotion-discount', 'promotion-discount']),
      commissionFee: idx(['selling fees', 'commission', 'referral fee']),
      shippingFee: idx(['fba fees', 'shipping-price', 'fulfilment fees']),
      otherFees: idx(['other', 'other transaction fees']),
      gstRate: idx(['tax-rate', 'gst rate']),
      status: idx(['order-status', 'item-status', 'Status']),
      buyerState: idx(['ship-state', 'buyer state']),
    );
  }

  OrderStatus _mapStatus(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('cancel')) return OrderStatus.cancelled;
    if (s.contains('return')) return OrderStatus.returned;
    if (s.contains('refund')) return OrderStatus.refunded;
    if (s.contains('ship')) return OrderStatus.shipped;
    if (s.contains('pending') || s.contains('unshipped')) {
      return OrderStatus.pending;
    }
    return OrderStatus.delivered;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '').trim();

  static int _toInt(String s, {int fallback = 0}) {
    if (s.isEmpty) return fallback;
    return int.tryParse(s.replaceAll(RegExp(r'[^0-9-]'), '')) ?? fallback;
  }

  static double _toDouble(String s, {double fallback = 0}) {
    if (s.isEmpty) return fallback;
    final cleaned = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned)?.abs() ?? fallback;
  }

  static DateTime _toDate(String s) {
    if (s.isEmpty) return DateTime.now();
    // Try ISO first (Amazon uses ISO-8601), then common dd-MM-yyyy / dd/MM/yyyy.
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    final m = RegExp(r'(\d{1,4})[-/](\d{1,2})[-/](\d{1,4})').firstMatch(s);
    if (m != null) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      final c = int.parse(m.group(3)!);
      // Heuristic: if first group is 4 digits it's the year (yyyy-MM-dd),
      // otherwise treat as dd-MM-yyyy.
      if (a > 31) return DateTime(a, b, c);
      return DateTime(c, b, a);
    }
    return DateTime.now();
  }
}

class _ColumnMap {
  final int orderId;
  final int orderDate;
  final int sku;
  final int productName;
  final int quantity;
  final int unitPrice;
  final int discount;
  final int commissionFee;
  final int shippingFee;
  final int otherFees;
  final int gstRate;
  final int status;
  final int buyerState;

  const _ColumnMap({
    required this.orderId,
    required this.orderDate,
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.commissionFee,
    required this.shippingFee,
    required this.otherFees,
    required this.gstRate,
    required this.status,
    required this.buyerState,
  });
}
