import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sale.dart';

/// Exports sales (and a GST summary) to CSV files and opens the share sheet.
class CsvExportService {
  Future<File> exportSales(List<Sale> sales) async {
    final rows = <List<Object?>>[
      [
        'Marketplace',
        'Order ID',
        'Order Date',
        'SKU',
        'Product',
        'Qty',
        'Unit Price',
        'Discount',
        'Gross Amount',
        'Taxable Value',
        'GST Rate %',
        'CGST',
        'SGST',
        'IGST',
        'Commission',
        'Shipping Fee',
        'Other Fees',
        'Cost',
        'Net Profit',
        'Net Settlement',
        'Status',
      ],
      ...sales.map(
        (s) => [
          s.marketplace.label,
          s.orderId,
          s.orderDate.toIso8601String(),
          s.sku,
          s.productName,
          s.quantity,
          s.unitPrice,
          s.discount,
          _r(s.grossAmount),
          _r(s.taxableValue),
          s.gstRate,
          _r(s.cgst),
          _r(s.sgst),
          _r(s.igst),
          s.commissionFee,
          s.shippingFee,
          s.otherFees,
          _r(s.totalCost),
          _r(s.netProfit),
          _r(s.netSettlement),
          s.status.label,
        ],
      ),
    ];
    return _writeAndShare('sales_export', rows);
  }

  /// GST summary grouped by rate — the shape needed for GSTR filing prep.
  Future<File> exportGstSummary(List<Sale> sales) async {
    final byRate = <double, List<double>>{}; // rate -> [taxable, cgst, sgst, igst]
    for (final s in sales) {
      if (!s.status.countsAsSale) continue;
      final agg = byRate.putIfAbsent(s.gstRate, () => [0, 0, 0, 0]);
      agg[0] += s.taxableValue;
      agg[1] += s.cgst;
      agg[2] += s.sgst;
      agg[3] += s.igst;
    }

    final rows = <List<Object?>>[
      ['GST Rate %', 'Taxable Value', 'CGST', 'SGST', 'IGST', 'Total GST'],
      ...(byRate.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map(
        (e) => [
          e.key,
          _r(e.value[0]),
          _r(e.value[1]),
          _r(e.value[2]),
          _r(e.value[3]),
          _r(e.value[1] + e.value[2] + e.value[3]),
        ],
      ),
    ];
    return _writeAndShare('gst_summary', rows);
  }

  Future<File> _writeAndShare(String prefix, List<List<Object?>> rows) async {
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, '${prefix}_$stamp.csv'));
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Sales Tracker export');
    return file;
  }

  static double _r(double v) => double.parse(v.toStringAsFixed(2));
}
