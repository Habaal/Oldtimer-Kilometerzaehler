import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';
import 'tables.dart';

class DatabaseHelper {
  static const _databaseName = 'oldtimer_km_log.db';
  static const _databaseVersion = 2;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(Tables.createVehicles);
    await db.execute(Tables.createTrips);
    await db.execute(Tables.createLocationPoints);
    await db.execute(Tables.indexTripsVehicleId);
    await db.execute(Tables.indexTripsStartTimestamp);
    await db.execute(Tables.indexLocationPointsTripId);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await Migrations.v1ZuV2(db);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
