import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Prüft ob der Standortdienst aktiviert und die Berechtigung erteilt ist.
  Future<bool> berechtigungPruefen() async {
    final serviceAktiv = await Geolocator.isLocationServiceEnabled();
    if (!serviceAktiv) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Prüft ob die "Immer erlauben"-Berechtigung erteilt ist (nötig für Hintergrund).
  Future<bool> hintergrundBerechtigungPruefen() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Fordert die "Immer erlauben"-Berechtigung an.
  Future<LocationPermission> hintergrundBerechtigungAnfordern() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Aktuelle Position abfragen.
  Future<Position?> aktuellePosition({
    LocationAccuracy genauigkeit = LocationAccuracy.high,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: genauigkeit),
      );
    } catch (_) {
      return null;
    }
  }

  /// Öffnet die App-Einstellungen (falls Berechtigung permanent verweigert).
  Future<bool> einstellungenOeffnen() async {
    return Geolocator.openAppSettings();
  }

  /// Öffnet die Standort-Einstellungen des Geräts.
  Future<bool> standortEinstellungenOeffnen() async {
    return Geolocator.openLocationSettings();
  }
}
