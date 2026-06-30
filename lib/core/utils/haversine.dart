import 'dart:math';

const double _erdRadiusKm = 6371.0;

/// Berechnet die Entfernung zwischen zwei Koordinaten in Kilometern
/// nach der Haversine-Formel (Großkreisdistanz auf der Erdkugel).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _zuRadiant(lat2 - lat1);
  final dLng = _zuRadiant(lng2 - lng1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_zuRadiant(lat1)) *
          cos(_zuRadiant(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return _erdRadiusKm * c;
}

double _zuRadiant(double grad) => grad * pi / 180.0;
