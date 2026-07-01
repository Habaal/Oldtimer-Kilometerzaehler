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
}
