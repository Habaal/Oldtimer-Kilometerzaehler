import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/utils/haversine.dart';
import '../data/models/location_point.dart';
import '../data/models/trip.dart';
import '../data/repositories/location_point_repository.dart';
import '../data/repositories/trip_repository.dart';
import 'distance_calculator.dart';
import 'geocoding_service.dart';

/// Zustände des Fahrterkennungs-Automaten
enum TrackingZustand { idle, detecting, tripActive, stopping }

/// Erkennt automatisch Fahrtbeginn und -ende anhand von GPS-Daten.
///
/// Zustandsübergänge:
///   IDLE → DETECTING:     Geschwindigkeit > 8 km/h erkannt
///   DETECTING → ACTIVE:   Geschwindigkeit > 8 km/h für ≥ 5 Sekunden
///   DETECTING → IDLE:     Geschwindigkeit fällt unter Schwelle
///   ACTIVE → STOPPING:    Geschwindigkeit < 2 km/h
///   STOPPING → ACTIVE:    Geschwindigkeit > 8 km/h innerhalb 3 Minuten
///   STOPPING → IDLE:      3 Minuten Stillstand → Trip wird gespeichert
class TripDetectionService {
  final TripRepository _tripRepo;
  final LocationPointRepository _pointRepo;
  final GeocodingService _geocoding;

  TrackingZustand _zustand = TrackingZustand.idle;
  String? _aktuellerTripId;
  double _akkumulierteDistanzKm = 0.0;
  LocationPoint? _letzterGueltigerPunkt;
  DateTime? _detectingStart;
  DateTime? _stoppingStart;
  Position? _ersterPunkt;
  Position? _vorherigePosition;
  DateTime? _vorherigeZeit;

  final void Function(TrackingZustand zustand)? onZustandGeaendert;
  final void Function(String tripId, double distanzKm)? onDistanzAktualisiert;
  final void Function(String tripId)? onTripGestartet;
  final void Function(String tripId, double gesamtKm)? onTripBeendet;

  TripDetectionService({
    TripRepository? tripRepo,
    LocationPointRepository? pointRepo,
    GeocodingService? geocoding,
    this.onZustandGeaendert,
    this.onDistanzAktualisiert,
    this.onTripGestartet,
    this.onTripBeendet,
  })  : _tripRepo = tripRepo ?? TripRepository(),
        _pointRepo = pointRepo ?? LocationPointRepository(),
        _geocoding = geocoding ?? GeocodingService();

  TrackingZustand get zustand => _zustand;
  String? get aktuellerTripId => _aktuellerTripId;
  double get aktuelleDistanzKm => _akkumulierteDistanzKm;

  /// Berechnet die Geschwindigkeit in km/h.
  /// Nutzt die GPS-Geschwindigkeit wenn verfügbar (>= 0),
  /// sonst berechnet aus Distanz zwischen aufeinanderfolgenden Positionen.
  double _geschwindigkeitBerechnen(Position position) {
    final gpsSpeed = position.speed;
    if (gpsSpeed >= 0) return gpsSpeed * 3.6;

    if (_vorherigePosition != null && _vorherigeZeit != null) {
      final distanzKm = haversineKm(
        _vorherigePosition!.latitude,
        _vorherigePosition!.longitude,
        position.latitude,
        position.longitude,
      );
      final zeitSekunden =
          DateTime.now().difference(_vorherigeZeit!).inMilliseconds / 1000.0;
      if (zeitSekunden > 0) {
        return (distanzKm / zeitSekunden) * 3600;
      }
    }
    return 0.0;
  }

  /// Verarbeitet einen neuen GPS-Punkt und aktualisiert den Zustandsautomaten.
  Future<void> positionVerarbeiten(Position position) async {
    final geschwindigkeitKmh = _geschwindigkeitBerechnen(position);
    final jetzt = DateTime.now();

    _vorherigePosition = position;
    _vorherigeZeit = jetzt;

    switch (_zustand) {
      case TrackingZustand.idle:
        if (geschwindigkeitKmh > TrackingConstants.speedThresholdKmh) {
          _detectingStart = jetzt;
          _ersterPunkt = position;
          _zustandSetzen(TrackingZustand.detecting);
        }

      case TrackingZustand.detecting:
        if (geschwindigkeitKmh < TrackingConstants.speedThresholdKmh) {
          _zustandSetzen(TrackingZustand.idle);
        } else if (_detectingStart != null &&
            jetzt.difference(_detectingStart!) >=
                TrackingConstants.confirmDuration) {
          await _tripStarten(position);
          _zustandSetzen(TrackingZustand.tripActive);
        }

      case TrackingZustand.tripActive:
        await _punktSpeichern(position);
        if (geschwindigkeitKmh < TrackingConstants.stopSpeedKmh) {
          _stoppingStart = jetzt;
          _zustandSetzen(TrackingZustand.stopping);
        }

      case TrackingZustand.stopping:
        if (geschwindigkeitKmh > TrackingConstants.speedThresholdKmh) {
          _zustandSetzen(TrackingZustand.tripActive);
          await _punktSpeichern(position);
        } else if (_stoppingStart != null &&
            jetzt.difference(_stoppingStart!) >=
                TrackingConstants.stopTimeout) {
          await _tripBeenden();
          _zustandSetzen(TrackingZustand.idle);
        }
    }
  }

  /// Startet einen Trip manuell (Override).
  Future<void> manuellStarten(String vehicleId, Position position) async {
    if (_zustand == TrackingZustand.tripActive) return;

    _ersterPunkt = position;
    await _tripStarten(position, vehicleId: vehicleId);
    _zustandSetzen(TrackingZustand.tripActive);
  }

  /// Stoppt den aktuellen Trip manuell.
  Future<void> manuellStoppen() async {
    if (_aktuellerTripId == null) return;
    await _tripBeenden();
    _zustandSetzen(TrackingZustand.idle);
  }

  /// Erzwingt Trip-Ende (z.B. wenn der Service beendet wird).
  Future<void> erzwungenStoppen() async {
    if (_aktuellerTripId != null) {
      await _tripBeenden();
    }
    _zustandSetzen(TrackingZustand.idle);
  }

  String get statusText {
    switch (_zustand) {
      case TrackingZustand.idle:
        return 'Bereit – warte auf Fahrtbeginn';
      case TrackingZustand.detecting:
        return 'Bewegung erkannt…';
      case TrackingZustand.tripActive:
        return 'Fahrt aktiv – ${_akkumulierteDistanzKm.toStringAsFixed(1)} km';
      case TrackingZustand.stopping:
        return 'Stillstand erkannt – warte…';
    }
  }

  void _zustandSetzen(TrackingZustand neuerZustand) {
    _zustand = neuerZustand;
    onZustandGeaendert?.call(neuerZustand);
  }

  bool _istFirmenfahrt = false;
  double? _kilometerstandStart;

  void fahrtTypSetzen({bool istFirmenfahrt = false, double? kilometerstandStart}) {
    _istFirmenfahrt = istFirmenfahrt;
    _kilometerstandStart = kilometerstandStart;
  }

  Future<void> _tripStarten(Position position, {String? vehicleId}) async {
    final id = const Uuid().v4();
    _aktuellerTripId = id;
    _akkumulierteDistanzKm = 0.0;
    _letzterGueltigerPunkt = null;

    String? startOrt;
    try {
      startOrt = await _geocoding.ortsnameVonKoordinaten(
        position.latitude,
        position.longitude,
      );
    } catch (_) {}

    final trip = Trip(
      id: id,
      vehicleId: vehicleId ?? '',
      startTimestamp: DateTime.now(),
      startOrt: startOrt,
      istFirmenfahrt: _istFirmenfahrt,
      kilometerstandStart: _kilometerstandStart,
    );
    await _tripRepo.einfuegen(trip);
    onTripGestartet?.call(id);

    await _punktSpeichern(position);
  }

  Future<void> _tripBeenden() async {
    if (_aktuellerTripId == null) return;

    final tripId = _aktuellerTripId!;

    // Trip mit kurzer Distanz verwerfen
    if (_akkumulierteDistanzKm < TrackingConstants.minTripDistanceKm) {
      await _tripRepo.loeschen(tripId);
      await _pointRepo.fuerTripLoeschen(tripId);
    } else {
      String? endOrt;
      if (_letzterGueltigerPunkt != null) {
        try {
          endOrt = await _geocoding.ortsnameVonKoordinaten(
            _letzterGueltigerPunkt!.lat,
            _letzterGueltigerPunkt!.lng,
          );
        } catch (_) {}
      }

      final trip = await _tripRepo.abrufen(tripId);
      if (trip != null) {
        final kmEnde = _kilometerstandStart != null
            ? _kilometerstandStart! + _akkumulierteDistanzKm
            : null;
        await _tripRepo.aktualisieren(trip.copyWith(
          endTimestamp: DateTime.now(),
          distanceKm: _akkumulierteDistanzKm,
          endOrt: endOrt,
          kilometerstandEnde: kmEnde,
        ));
      }
    }

    onTripBeendet?.call(tripId, _akkumulierteDistanzKm);

    _aktuellerTripId = null;
    _akkumulierteDistanzKm = 0.0;
    _letzterGueltigerPunkt = null;
    _stoppingStart = null;
    _detectingStart = null;
    _ersterPunkt = null;
  }

  Future<void> _punktSpeichern(Position position) async {
    if (_aktuellerTripId == null) return;

    final punkt = LocationPoint(
      tripId: _aktuellerTripId!,
      timestamp: DateTime.now(),
      lat: position.latitude,
      lng: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
    );

    await _pointRepo.einfuegen(punkt);

    if (_letzterGueltigerPunkt != null) {
      final distanz = DistanceCalculator.inkrementelleDistanzKm(
        _letzterGueltigerPunkt!,
        punkt,
      );
      if (distanz > 0) {
        _akkumulierteDistanzKm += distanz;
        _letzterGueltigerPunkt = punkt;
        onDistanzAktualisiert?.call(_aktuellerTripId!, _akkumulierteDistanzKm);
      }
    } else {
      _letzterGueltigerPunkt = punkt;
    }
  }
}
