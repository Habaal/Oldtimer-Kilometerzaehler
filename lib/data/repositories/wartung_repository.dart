import '../database/database_helper.dart';
import '../models/wartung.dart';

class WartungRepository {
  final DatabaseHelper _dbHelper;

  WartungRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Wartung>> fuerFahrzeug(String vehicleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'wartungen',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'datum DESC',
    );
    return maps.map((m) => Wartung.fromMap(m)).toList();
  }

  Future<void> einfuegen(Wartung wartung) async {
    final db = await _dbHelper.database;
    await db.insert('wartungen', wartung.toMap());
  }

  Future<void> aktualisieren(Wartung wartung) async {
    final db = await _dbHelper.database;
    await db.update(
      'wartungen',
      wartung.toMap(),
      where: 'id = ?',
      whereArgs: [wartung.id],
    );
  }

  Future<void> loeschen(String id) async {
    final db = await _dbHelper.database;
    await db.delete('wartungen', where: 'id = ?', whereArgs: [id]);
  }
}
