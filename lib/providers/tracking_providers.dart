import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/foreground_task_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/trip_detection_service.dart';

final trackingZustandProvider =
    NotifierProvider<_TrackingZustandNotifier, TrackingZustand>(
  _TrackingZustandNotifier.new,
);

class _TrackingZustandNotifier extends Notifier<TrackingZustand> {
  @override
  TrackingZustand build() => TrackingZustand.idle;
}

final serviceAktivProvider =
    NotifierProvider<_ServiceAktivNotifier, bool>(_ServiceAktivNotifier.new);

class _ServiceAktivNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

final aktuelleDistanzProvider =
    NotifierProvider<_AktuelleDistanzNotifier, double>(
  _AktuelleDistanzNotifier.new,
);

class _AktuelleDistanzNotifier extends Notifier<double> {
  @override
  double build() => 0.0;
}

final aktuellerTripIdProvider =
    NotifierProvider<_AktuellerTripIdNotifier, String?>(
  _AktuellerTripIdNotifier.new,
);

class _AktuellerTripIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final aktuellePositionProvider =
    NotifierProvider<_AktuellePositionNotifier, ({double lat, double lng, double speed})?>(
  _AktuellePositionNotifier.new,
);

class _AktuellePositionNotifier extends Notifier<({double lat, double lng, double speed})?> {
  @override
  ({double lat, double lng, double speed})? build() => null;
}

final aktuellerOrtProvider =
    NotifierProvider<_AktuellerOrtNotifier, String?>(
  _AktuellerOrtNotifier.new,
);

class _AktuellerOrtNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final trackingControllerProvider =
    Provider<TrackingController>((ref) => TrackingController(ref));

class TrackingController {
  final Ref _ref;
  TripDetectionService? _tripDetection;
  String? _vehicleId;

  TrackingController(this._ref);

  Future<bool> starten(
    String vehicleId,
    String fahrzeugName, {
    bool istFirmenfahrt = false,
    double? kilometerstandStart,
  }) async {
    final locationService = LocationService();
    final erlaubt = await locationService.berechtigungPruefen();
    if (!erlaubt) return false;

    _vehicleId = vehicleId;

    _tripDetection = TripDetectionService(
      onZustandGeaendert: (zustand) {
        _ref.read(trackingZustandProvider.notifier).state = zustand;
      },
      onDistanzAktualisiert: (tripId, distanz) {
        _ref.read(aktuelleDistanzProvider.notifier).state = distanz;
        _ref.read(aktuellerTripIdProvider.notifier).state = tripId;
        ForegroundTaskService.notificationAktualisieren(
          'Fahrt aktiv – ${distanz.toStringAsFixed(1)} km',
        );
      },
      onTripGestartet: (tripId) {
        _ref.read(aktuellerTripIdProvider.notifier).state = tripId;
        _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;
      },
      onTripBeendet: (tripId, gesamtKm) {
        _ref.read(aktuellerTripIdProvider.notifier).state = null;
        _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;
      },
    );

    _tripDetection!.fahrtTypSetzen(
      istFirmenfahrt: istFirmenfahrt,
      kilometerstandStart: kilometerstandStart,
    );

    ForegroundTaskService.init();
    final gestartet = await ForegroundTaskService.starten(fahrzeugName);
    if (gestartet) {
      _ref.read(serviceAktivProvider.notifier).state = true;
    }
    return gestartet;
  }

  Future<void> stoppen() async {
    await _tripDetection?.erzwungenStoppen();
    _tripDetection = null;
    _vehicleId = null;
    await ForegroundTaskService.stoppen();
    _ref.read(serviceAktivProvider.notifier).state = false;
    _ref.read(trackingZustandProvider.notifier).state = TrackingZustand.idle;
    _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;
    _ref.read(aktuellerTripIdProvider.notifier).state = null;
    _ref.read(aktuellePositionProvider.notifier).state = null;
    _ref.read(aktuellerOrtProvider.notifier).state = null;
  }

  void positionVerarbeiten(Position position) {
    _tripDetection?.positionVerarbeiten(position);
  }

  Future<void> manuellStarten() async {
    if (_tripDetection == null || _vehicleId == null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _tripDetection!.manuellStarten(_vehicleId!, position);
    } catch (_) {}
  }

  Future<void> manuellStoppen() async {
    await _tripDetection?.manuellStoppen();
  }

  DateTime? _letzteOrtAbfrage;

  void ortAktualisieren(double lat, double lng) async {
    final jetzt = DateTime.now();
    if (_letzteOrtAbfrage != null &&
        jetzt.difference(_letzteOrtAbfrage!) < const Duration(seconds: 15)) {
      return;
    }
    _letzteOrtAbfrage = jetzt;
    final ort = await GeocodingService().ortsnameVonKoordinaten(lat, lng);
    _ref.read(aktuellerOrtProvider.notifier).state = ort;
  }
}
