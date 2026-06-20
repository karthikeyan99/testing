import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../models/business_profile.dart';

/// Persists the [BusinessProfile] in the key-value `settings` table.
class SettingsRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<BusinessProfile> getProfile() async {
    final db = await _db;
    final rows = await db.query('settings');
    final map = {
      for (final r in rows) r['key'] as String: (r['value'] as String?) ?? '',
    };
    return BusinessProfile.fromMap(map);
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    final db = await _db;
    final batch = db.batch();
    profile.toMap().forEach((key, value) {
      batch.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }
}
