import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/enums.dart';
import '../models/sale.dart';
import 'csv_import_service.dart' show ImportResult;

/// Parses a Flipkart "Settled Transactions" .xlsx export.
///
/// The report is a multi-sheet workbook. The per-order settlement data lives in
/// the "Orders" sheet, which has category banners on row 1, the real column
/// headers on row 2, and data from row 4 onward. Columns are matched by header
/// name (normalised) so the parser tolerates minor layout changes.
///
/// The key column is **"Bank Settlement Value"** — the net amount actually paid
/// to the seller after commission, fees and GST — grouped by **"Payment Date"**.
class FlipkartSettlementParser {
  static const _sheetName = 'Orders';
  static const _headerRow = 1; // 0-based -> Excel row 2
  static const _firstDataRow = 3; // 0-based -> Excel row 4

  ImportResult parse(Uint8List bytes) {
    final Excel book;
    try {
      book = Excel.decodeBytes(bytes);
    } catch (e) {
      return ImportResult(sales: const [], warnings: ['Not a valid .xlsx: $e']);
    }

    final sheet = book.tables[_sheetName];
    if (sheet == null) {
      return ImportResult(
        sales: const [],
        warnings: [
          'No "Orders" sheet found. Is this the Flipkart Settled '
              'Transactions report? Sheets: ${book.tables.keys.join(", ")}',
        ],
      );
    }

    final rows = sheet.rows;
    if (rows.length <= _firstDataRow) {
      return const ImportResult(sales: [], warnings: ['No data rows found.']);
    }

    // Build header -> column-index map from row 2.
    final header = <String, int>{};
    final headerCells = rows[_headerRow];
    for (var c = 0; c < headerCells.length; c++) {
      final name = _norm(_cellString(headerCells[c]));
      if (name.isNotEmpty) header.putIfAbsent(name, () => c);
    }

    int col(List<String> prefixes) {
      for (final p in prefixes) {
        final np = _norm(p);
        for (final entry in header.entries) {
          if (entry.key.startsWith(np)) return entry.value;
        }
      }
      return -1;
    }

    final cNet = col(['bank settlement value']);
    final cPay = col(['payment date']);
    final cOrderId = col(['order id']);
    final cSale = col(['sale amount (rs.)', 'sale amount']);
    final cMpFee = col(['marketplace fee']);
    final cTaxes = col(['taxes (rs.)']);
    final cSku = col(['seller sku']);
    final cQty = col(['quantity']);
    final cOrderDate = col(['order date']);
    final cReturn = col(['item return status']);
    final cGst = col(['item gst rate']);
    final cName = col(['product sub category']);

    final warnings = <String>[];
    if (cNet == -1) {
      warnings.add('Could not find the "Bank Settlement Value" column.');
    }
    if (cPay == -1) {
      warnings.add('Could not find the "Payment Date" column.');
    }

    final sales = <Sale>[];
    var skipped = 0;

    for (var r = _firstDataRow; r < rows.length; r++) {
      final row = rows[r];
      String cell(int i) =>
          (i >= 0 && i < row.length) ? _cellString(row[i]) : '';
      double cellNum(int i) =>
          (i >= 0 && i < row.length) ? _cellDouble(row[i]) : 0;
      DateTime? cellDate(int i) =>
          (i >= 0 && i < row.length) ? _cellDate(row[i]) : null;

      final orderId = cell(cOrderId);
      final net = cellNum(cNet);
      final sale = cellNum(cSale);
      if (orderId.isEmpty && net == 0 && sale == 0) {
        skipped++;
        continue;
      }

      final qty = cellNum(cQty).round().clamp(1, 1 << 30).toInt();
      final returnStatus = cell(cReturn);
      final isReturn = net < 0 ||
          (returnStatus.isNotEmpty &&
              !{'na', 'no', 'none', ''}.contains(returnStatus.toLowerCase()));

      sales.add(
        Sale(
          marketplace: Marketplace.flipkart,
          orderId: orderId.isEmpty ? 'FK-$r' : orderId,
          orderDate: cellDate(cOrderDate) ?? cellDate(cPay) ?? DateTime.now(),
          sku: cell(cSku),
          productName: cell(cName),
          quantity: qty,
          unitPrice: qty == 0 ? sale : sale / qty,
          commissionFee: cellNum(cMpFee).abs(),
          otherFees: cellNum(cTaxes).abs(),
          gstRate: cGst == -1 ? 0 : cellNum(cGst),
          status: isReturn ? OrderStatus.returned : OrderStatus.delivered,
          settlementValue: net,
          settlementDate: cellDate(cPay),
        ),
      );
    }

    return ImportResult(sales: sales, skipped: skipped, warnings: warnings);
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Converts a cell to a plain string across the excel package's CellValue
  /// subtypes. In excel 4.x text cells hold a rich-text [TextSpan], so the
  /// plain text is reconstructed from its `text`/`children`.
  static String _cellString(Data? cell) {
    final v = cell?.value;
    if (v == null) return '';
    if (v is TextCellValue) return _spanText(v.value);
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is DateCellValue) return '${v.year}-${v.month}-${v.day}';
    if (v is DateTimeCellValue) return '${v.year}-${v.month}-${v.day}';
    return v.toString().trim();
  }

  static String _spanText(TextSpan? span) {
    if (span == null) return '';
    final buf = StringBuffer(span.text ?? '');
    for (final child in span.children ?? const <TextSpan>[]) {
      buf.write(_spanText(child));
    }
    return buf.toString().trim();
  }

  static double _cellDouble(Data? cell) {
    final v = cell?.value;
    if (v == null) return 0;
    if (v is IntCellValue) return v.value.toDouble();
    if (v is DoubleCellValue) return v.value;
    final s = _cellString(cell).replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(s) ?? 0;
  }

  static DateTime? _cellDate(Data? cell) {
    final v = cell?.value;
    if (v == null) return null;
    if (v is DateCellValue) return DateTime(v.year, v.month, v.day);
    if (v is DateTimeCellValue) {
      return DateTime(v.year, v.month, v.day, v.hour, v.minute, v.second);
    }
    final s = _cellString(cell).trim();
    if (s.isEmpty || s.toLowerCase() == 'na') return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final m = RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(s);
    if (m != null) {
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    }
    return null;
  }
}
