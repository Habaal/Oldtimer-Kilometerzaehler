import 'package:sqflite/sqflite.dart';

class Migrations {
  Migrations._();

  static Future<void> v1ZuV2(Database db) async {
    await db.execute('ALTER TABLE vehicles ADD COLUMN ist_firmenwagen INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE vehicles ADD COLUMN kilometerstand REAL');
    await db.execute('ALTER TABLE trips ADD COLUMN ist_firmenfahrt INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE trips ADD COLUMN kilometerstand_start REAL');
    await db.execute('ALTER TABLE trips ADD COLUMN kilometerstand_ende REAL');
  }

  static Future<void> v2ZuV3(Database db) async {
    await _spalteHinzufuegenFallsFehlt(db, 'vehicles', 'ist_firmenwagen', 'INTEGER NOT NULL DEFAULT 0');
    await _spalteHinzufuegenFallsFehlt(db, 'vehicles', 'kilometerstand', 'REAL');
    await _spalteHinzufuegenFallsFehlt(db, 'trips', 'ist_firmenfahrt', 'INTEGER NOT NULL DEFAULT 0');
    await _spalteHinzufuegenFallsFehlt(db, 'trips', 'kilometerstand_start', 'REAL');
    await _spalteHinzufuegenFallsFehlt(db, 'trips', 'kilometerstand_ende', 'REAL');
  }

  static Future<void> _spalteHinzufuegenFallsFehlt(
    Database db,
    String tabelle,
    String spalte,
    String typ,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($tabelle)');
    final existiert = info.any((row) => row['name'] == spalte);
    if (!existiert) {
      await db.execute('ALTER TABLE $tabelle ADD COLUMN $spalte $typ');
    }
  }
}
