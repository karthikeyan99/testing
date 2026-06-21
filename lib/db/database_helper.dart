import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema migrations for the app.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'sales_tracker.db';
  static const _dbVersion = 3;

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
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE sales ADD COLUMN settlementValue REAL');
      await db.execute('ALTER TABLE sales ADD COLUMN settlementDate INTEGER');
      // Settlement reports can have several rows per order (sale + return), so
      // the strict unique key no longer applies; re-import is handled by
      // replacing rows within the settled date range instead.
      await db.execute('DROP INDEX IF EXISTS idx_sales_order');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_settle ON sales (settlementDate)',
      );
    }
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
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
        notes TEXT,
        settlementValue REAL,
        settlementDate INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sales_order ON sales (marketplace, orderId)',
    );
    await db.execute('CREATE INDEX idx_sales_date ON sales (orderDate)');
    await db.execute('CREATE INDEX idx_sales_settle ON sales (settlementDate)');

    await _createSettingsTable(db);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
