import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/enums.dart';
import '../models/sale.dart';

/// Optional filters applied when querying sales.
class SaleFilter {
  final DateTime? from;
  final DateTime? to;
  final String? marketplace; // Marketplace.name
  final String? status; // OrderStatus.name
  final String? search; // matches orderId / sku / productName

  const SaleFilter({
    this.from,
    this.to,
    this.marketplace,
    this.status,
    this.search,
  });
}

class SaleRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Sale>> getAll([SaleFilter filter = const SaleFilter()]) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (filter.from != null) {
      where.add('orderDate >= ?');
      args.add(filter.from!.millisecondsSinceEpoch);
    }
    if (filter.to != null) {
      where.add('orderDate <= ?');
      args.add(filter.to!.millisecondsSinceEpoch);
    }
    if (filter.marketplace != null) {
      where.add('marketplace = ?');
      args.add(filter.marketplace);
    }
    if (filter.status != null) {
      where.add('status = ?');
      args.add(filter.status);
    }
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      where.add('(orderId LIKE ? OR sku LIKE ? OR productName LIKE ?)');
      final q = '%${filter.search!.trim()}%';
      args.addAll([q, q, q]);
    }

    final rows = await db.query(
      'sales',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'orderDate DESC',
    );
    return rows.map(Sale.fromMap).toList();
  }

  Future<int> insert(Sale sale) async {
    final db = await _db;
    return db.insert(
      'sales',
      sale.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Bulk insert used by imports. Returns the number of rows written.
  Future<int> insertAll(List<Sale> sales) async {
    final db = await _db;
    final batch = db.batch();
    for (final s in sales) {
      batch.insert('sales', s.toMap()..remove('id'));
    }
    final result = await batch.commit(noResult: false);
    return result.length;
  }

  /// Idempotent settlement import: clears existing rows for [marketplace] whose
  /// settlement date falls within the imported range, then inserts the new set.
  /// This makes re-importing the same (or an overlapping) report safe.
  Future<int> replaceSettlement(
    Marketplace marketplace,
    List<Sale> sales,
  ) async {
    if (sales.isEmpty) return 0;
    final dates = sales
        .map((s) => s.settlementDate)
        .whereType<DateTime>()
        .map((d) => d.millisecondsSinceEpoch)
        .toList();
    final db = await _db;
    if (dates.isNotEmpty) {
      dates.sort();
      await db.delete(
        'sales',
        where: 'marketplace = ? AND settlementDate BETWEEN ? AND ?',
        whereArgs: [marketplace.name, dates.first, dates.last],
      );
    }
    return insertAll(sales);
  }

  Future<int> update(Sale sale) async {
    final db = await _db;
    return db.update(
      'sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    final db = await _db;
    return db.delete('sales');
  }
}
