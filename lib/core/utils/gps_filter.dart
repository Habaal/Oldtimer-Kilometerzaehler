import '../constants.dart';
import 'haversine.dart';

/// Filtert unbrauchbare GPS-Punkte heraus.
/// Kriterien:
/// - Genauigkeit schlechter als minAccuracyMeters → verwerfen
/// - Berechnete Geschwindigkeit > maxSpeedKmh → Ausreißer
/// - Distanz zum Vorgänger < minDistanceMeters → Stillstand-Rauschen
class GpsFilter {
  GpsFilter._();

  /// Prüft ob ein GPS-Punkt gültig ist.
  /// [accuracy] in Metern, [speed] in m/s (optional, direkt vom GPS).
  /// [previousLat]/[previousLng]/[previousTimestamp] sind der letzte gültige Punkt.
  static bool istGueltig({
    required double lat,
    required double lng,
    required double? accuracy,
    required double? speed,
    double? previousLat,
    double? previousLng,
    DateTime? previousTimestamp,
    DateTime? currentTimestamp,
  }) {
    // Genauigkeit zu schlecht
    if (accuracy != null && accuracy > TrackingConstants.minAccuracyMeters) {
      return false;
    }

    // GPS-Geschwindigkeit unplausibel (in km/h umrechnen)
    if (speed != null && speed * 3.6 > TrackingConstants.maxSpeedKmh) {
      return false;
    }

    // Vergleich mit Vorgängerpunkt
    if (previousLat != null &&
        previousLng != null &&
        previousTimestamp != null &&
        currentTimestamp != null) {
      final distanzKm = haversineKm(previousLat, previousLng, lat, lng);
      final distanzMeter = distanzKm * 1000;

      // Zu nah am Vorgänger → Stillstand-Rauschen
      if (distanzMeter < TrackingConstants.minDistanceMeters) {
        return false;
      }

      // Berechnete Geschwindigkeit prüfen
      final zeitDiffSekunden =
          currentTimestamp.difference(previousTimestamp).inMilliseconds / 1000.0;
      if (zeitDiffSekunden > 0) {
        final berechneteGeschwindigkeitKmh =
            (distanzKm / zeitDiffSekunden) * 3600;
        if (berechneteGeschwindigkeitKmh > TrackingConstants.maxSpeedKmh) {
          return false;
        }
      }
    }

    return true;
  }
}
