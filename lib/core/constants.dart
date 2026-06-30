class TrackingConstants {
  TrackingConstants._();

  // Geschwindigkeitsschwellen (km/h)
  static const double speedThresholdKmh = 8.0;
  static const double stopSpeedKmh = 2.0;

  // Zeitkonstanten
  static const Duration confirmDuration = Duration(seconds: 5);
  static const Duration stopTimeout = Duration(minutes: 3);
  static const Duration idleGpsInterval = Duration(seconds: 30);
  static const Duration activeGpsInterval = Duration(seconds: 5);
  static const Duration detectingGpsInterval = Duration(seconds: 3);
  static const Duration stoppingGpsInterval = Duration(seconds: 10);

  // GPS-Filter
  static const double minAccuracyMeters = 50.0;
  static const double minDistanceMeters = 5.0;
  static const double maxSpeedKmh = 200.0;

  // Mindest-Trip-Distanz (kürzere werden verworfen)
  static const double minTripDistanceKm = 0.2;
}
