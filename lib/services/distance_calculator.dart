import '../core/utils/gps_filter.dart';
import '../core/utils/haversine.dart';
import '../data/models/location_point.dart';

class DistanceCalculator {
  DistanceCalculator._();

  /// Berechnet die Gesamtdistanz aus einer Liste von GPS-Punkten.
  /// Wendet den GPS-Filter an und summiert Haversine-Distanzen
  /// zwischen aufeinanderfolgenden gültigen Punkten.
  static double gesamtKm(List<LocationPoint> punkte) {
    if (punkte.length < 2) return 0.0;

    double gesamt = 0.0;
    LocationPoint? letzterGueltig;

    for (final punkt in punkte) {
      if (letzterGueltig == null) {
        letzterGueltig = punkt;
        continue;
      }

      final istGueltig = GpsFilter.istGueltig(
        lat: punkt.lat,
        lng: punkt.lng,
        accuracy: punkt.accuracy,
        speed: punkt.speed,
        previousLat: letzterGueltig.lat,
        previousLng: letzterGueltig.lng,
        previousTimestamp: letzterGueltig.timestamp,
        currentTimestamp: punkt.timestamp,
      );

      if (istGueltig) {
        gesamt += haversineKm(
          letzterGueltig.lat,
          letzterGueltig.lng,
          punkt.lat,
          punkt.lng,
        );
        letzterGueltig = punkt;
      }
    }

    return gesamt;
  }

  /// Berechnet die inkrementelle Distanz zwischen zwei Punkten.
  /// Gibt 0.0 zurück wenn der neue Punkt ungültig ist.
  static double inkrementelleDistanzKm(
    LocationPoint vorheriger,
    LocationPoint neuer,
  ) {
    final istGueltig = GpsFilter.istGueltig(
      lat: neuer.lat,
      lng: neuer.lng,
      accuracy: neuer.accuracy,
      speed: neuer.speed,
      previousLat: vorheriger.lat,
      previousLng: vorheriger.lng,
      previousTimestamp: vorheriger.timestamp,
      currentTimestamp: neuer.timestamp,
    );

    if (!istGueltig) return 0.0;

    return haversineKm(
      vorheriger.lat,
      vorheriger.lng,
      neuer.lat,
      neuer.lng,
    );
  }
}
