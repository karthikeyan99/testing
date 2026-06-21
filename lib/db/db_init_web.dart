import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web (Chrome/Edge): back sqflite with the WASM sqlite3 implementation.
/// Requires the one-time setup that copies the worker + wasm into web/:
///   dart run sqflite_common_ffi_web:setup
Future<void> initDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}
