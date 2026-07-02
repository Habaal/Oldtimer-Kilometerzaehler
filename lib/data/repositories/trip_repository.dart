import '../database/database_helper.dart';
import '../models/trip.dart';

class TripRepository {
  final DatabaseHelper _dbHelper;

  TripRepository([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Trip>> fuerFahrzeug(
    String vehicleId, {
    DateTime? von,
    DateTime? bis,
  }) async {
    final db = await _dbHelper.database;
    var where = 'vehicle_id = ?';
    final whereArgs = <dynamic>[vehicleId];

    if (von != null) {
      where += ' AND start_timestamp >= ?';
      whereArgs.add(von.toIso8601String());
    }
    if (bis != null) {
      where += ' AND start_timestamp <= ?';
      whereArgs.add(bis.toIso8601String());
    }

    final maps = await db.query(
      'trips',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'start_timestamp DESC',
    );
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  Future<Trip?> abrufen(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<void> einfuegen(Trip trip) async {
    final db = await _dbHelper.database;
    await db.insert('trips', trip.toMap());
  }

  Future<void> aktualisieren(Trip trip) async {
    final db = await _dbHelper.database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> loeschen(String id) async {
    final db = await _dbHelper.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  /// Berechnet die Gesamtkilometer für ein Fahrzeug in einem Zeitraum.
  /// Mit [nurPrivat] werden nur Privatfahrten gezählt (für den Sachbezug).
  Future<double> gesamtKm(
    String vehicleId, {
    DateTime? von,
    DateTime? bis,
    bool nurPrivat = false,
  }) async {
    final db = await _dbHelper.database;
    var where = 'vehicle_id = ? AND end_timestamp IS NOT NULL';
    final whereArgs = <dynamic>[vehicleId];

    if (nurPrivat) {
      where += ' AND ist_firmenfahrt = 0';
    }
    if (von != null) {
      where += ' AND start_timestamp >= ?';
      whereArgs.add(von.toIso8601String());
    }
    if (bis != null) {
      where += ' AND start_timestamp <= ?';
      whereArgs.add(bis.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(distance_km), 0.0) as total FROM trips WHERE $where',
      whereArgs,
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Kilometer pro Monat für ein Jahr.
  Future<Map<int, double>> monatsKm(String vehicleId, int jahr) async {
    final db = await _dbHelper.database;
    final von = DateTime(jahr, 1, 1).toIso8601String();
    final bis = DateTime(jahr, 12, 31, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        CAST(strftime('%m', start_timestamp) AS INTEGER) as monat,
        COALESCE(SUM(distance_km), 0.0) as total
      FROM trips
      WHERE vehicle_id = ?
        AND end_timestamp IS NOT NULL
        AND start_timestamp >= ?
        AND start_timestamp <= ?
      GROUP BY monat
      ORDER BY monat
    ''', [vehicleId, von, bis]);

    final map = <int, double>{};
    for (int i = 1; i <= 12; i++) {
      map[i] = 0.0;
    }
    for (final row in result) {
      final monat = row['monat'] as int;
      map[monat] = (row['total'] as num).toDouble();
    }
    return map;
  }
}
