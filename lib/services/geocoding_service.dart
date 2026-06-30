import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Ermittelt den Ortsnamen für gegebene Koordinaten.
  /// Gibt nur den Städte-/Ortsnamen zurück (kein exaktes Tracking).
  Future<String?> ortsnameVonKoordinaten(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final pm = placemarks.first;
      return pm.locality ?? pm.subAdministrativeArea ?? pm.administrativeArea;
    } catch (_) {
      return null;
    }
  }
}
