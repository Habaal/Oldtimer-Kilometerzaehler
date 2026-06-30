import '../database/database_helper.dart';
import '../models/vehicle.dart';

class VehicleRepository {
  final DatabaseHelper _dbHelper;

  VehicleRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Vehicle>> alleAbrufen() async {
    final db = await _dbHelper.database;
    final maps = await db.query('vehicles', orderBy: 'name ASC');
    return maps.map((m) => Vehicle.fromMap(m)).toList();
  }

  Future<Vehicle?> abrufen(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<Vehicle?> aktivesAbrufen() async {
    final db = await _dbHelper.database;
    final maps =
        await db.query('vehicles', where: 'aktiv = ?', whereArgs: [1]);
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  Future<void> einfuegen(Vehicle vehicle) async {
    final db = await _dbHelper.database;
    await db.insert('vehicles', vehicle.toMap());
  }

  Future<void> aktualisieren(Vehicle vehicle) async {
    final db = await _dbHelper.database;
    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> loeschen(String id) async {
    final db = await _dbHelper.database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  /// Setzt ein Fahrzeug als aktiv und deaktiviert alle anderen.
  Future<void> aktivSetzen(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('vehicles', {'aktiv': 0});
      await txn.update(
        'vehicles',
        {'aktiv': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Deaktiviert alle Fahrzeuge.
  Future<void> alleDeaktivieren() async {
    final db = await _dbHelper.database;
    await db.update('vehicles', {'aktiv': 0});
  }
}
