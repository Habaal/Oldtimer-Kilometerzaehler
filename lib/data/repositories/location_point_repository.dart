import '../database/database_helper.dart';
import '../models/location_point.dart';

class LocationPointRepository {
  final DatabaseHelper _dbHelper;

  LocationPointRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> einfuegen(LocationPoint point) async {
    final db = await _dbHelper.database;
    await db.insert('location_points', point.toMap());
  }

  Future<List<LocationPoint>> fuerTrip(String tripId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'location_points',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => LocationPoint.fromMap(m)).toList();
  }

  /// Löscht alle GPS-Punkte eines abgeschlossenen Trips (Speicherplatz sparen).
  Future<void> fuerTripLoeschen(String tripId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'location_points',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  /// Löscht alle GPS-Punkte für abgeschlossene Trips (Aufräumen).
  Future<int> abgeschlosseneLoeschen() async {
    final db = await _dbHelper.database;
    return db.rawDelete('''
      DELETE FROM location_points
      WHERE trip_id IN (
        SELECT id FROM trips WHERE end_timestamp IS NOT NULL
      )
    ''');
  }
}
