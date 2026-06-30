class Tables {
  Tables._();

  static const String createVehicles = '''
    CREATE TABLE vehicles (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      kennzeichen TEXT NOT NULL,
      baujahr INTEGER NOT NULL,
      jahres_limit_km REAL,
      aktiv INTEGER NOT NULL DEFAULT 0,
      foto_path TEXT,
      tracking_pausiert INTEGER NOT NULL DEFAULT 0,
      erstellt_am TEXT NOT NULL,
      aktualisiert_am TEXT NOT NULL
    )
  ''';

  static const String createTrips = '''
    CREATE TABLE trips (
      id TEXT PRIMARY KEY,
      vehicle_id TEXT NOT NULL,
      start_timestamp TEXT NOT NULL,
      end_timestamp TEXT,
      distance_km REAL NOT NULL DEFAULT 0.0,
      manuell_erfasst INTEGER NOT NULL DEFAULT 0,
      start_ort TEXT,
      end_ort TEXT,
      notiz TEXT,
      FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
    )
  ''';

  static const String createLocationPoints = '''
    CREATE TABLE location_points (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      trip_id TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      speed REAL,
      accuracy REAL,
      FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
    )
  ''';

  static const String indexTripsVehicleId =
      'CREATE INDEX idx_trips_vehicle_id ON trips(vehicle_id)';

  static const String indexTripsStartTimestamp =
      'CREATE INDEX idx_trips_start_timestamp ON trips(start_timestamp)';

  static const String indexLocationPointsTripId =
      'CREATE INDEX idx_location_points_trip_id ON location_points(trip_id)';
}
