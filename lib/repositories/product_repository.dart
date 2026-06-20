import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<List<Product>> getAll() async {
    final db = await _db;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> findBySku(String sku) async {
    final db = await _db;
    final rows = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> insert(Product product) async {
    final db = await _db;
    return db.insert(
      'products',
      product.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(Product product) async {
    final db = await _db;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Reduce stock for [sku] by [quantity] (used when a sale is recorded).
  Future<void> decrementStock(String sku, int quantity) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE products SET stock = stock - ? WHERE sku = ?',
      [quantity, sku],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
