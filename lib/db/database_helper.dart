import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema migrations for the app.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'sales_tracker.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        costPrice REAL NOT NULL DEFAULT 0,
        gstRate REAL NOT NULL DEFAULT 18,
        stock INTEGER NOT NULL DEFAULT 0,
        lowStockThreshold INTEGER NOT NULL DEFAULT 5,
        hsnCode TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        marketplace TEXT NOT NULL,
        orderId TEXT NOT NULL,
        orderDate INTEGER NOT NULL,
        sku TEXT NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unitPrice REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        commissionFee REAL NOT NULL DEFAULT 0,
        shippingFee REAL NOT NULL DEFAULT 0,
        otherFees REAL NOT NULL DEFAULT 0,
        costPrice REAL NOT NULL DEFAULT 0,
        gstRate REAL NOT NULL DEFAULT 18,
        isInterState INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'delivered',
        buyerState TEXT,
        notes TEXT
      )
    ''');

    // De-duplicate marketplace imports on (marketplace, orderId, sku).
    await db.execute('''
      CREATE UNIQUE INDEX idx_sales_order
      ON sales (marketplace, orderId, sku)
    ''');
    await db.execute('CREATE INDEX idx_sales_date ON sales (orderDate)');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
