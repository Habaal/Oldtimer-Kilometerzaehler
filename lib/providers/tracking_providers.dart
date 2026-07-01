import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    ForegroundTaskService.init();
    final gestartet = await ForegroundTaskService.starten(fahrzeugName);
    if (gestartet) {
      _ref.read(serviceAktivProvider.notifier).state = true;
      ForegroundTaskService.datenAnTaskSenden({
        'vehicleId': vehicleId,
        'istFirmenfahrt': istFirmenfahrt,
        'kilometerstandStart': kilometerstandStart,
      });
    }
    return gestartet;
  }

  Future<void> stoppen() async {
    await ForegroundTaskService.stoppen();
    _ref.read(serviceAktivProvider.notifier).state = false;
    _ref.read(trackingZustandProvider.notifier).state = TrackingZustand.idle;
    _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;
    _ref.read(aktuellerTripIdProvider.notifier).state = null;
    _ref.read(aktuellePositionProvider.notifier).state = null;
    _ref.read(aktuellerOrtProvider.notifier).state = null;
  }

  void manuellStarten() {
    ForegroundTaskService.datenAnTaskSenden({'action': 'manuellStarten'});
  }

  void manuellStoppen() {
    ForegroundTaskService.datenAnTaskSenden({'action': 'manuellStoppen'});
  }

  void datenVerarbeiten(Map<String, dynamic> daten) {
    switch (daten['type']) {
      case 'zustand':
        final name = daten['zustand'] as String;
        final zustand = TrackingZustand.values.firstWhere(
          (z) => z.name == name,
          orElse: () => TrackingZustand.idle,
        );
        _ref.read(trackingZustandProvider.notifier).state = zustand;

      case 'distanz':
        _ref.read(aktuelleDistanzProvider.notifier).state =
            (daten['distanzKm'] as num).toDouble();
        _ref.read(aktuellerTripIdProvider.notifier).state =
            daten['tripId'] as String?;

      case 'tripGestartet':
        _ref.read(aktuellerTripIdProvider.notifier).state =
            daten['tripId'] as String?;
        _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;

      case 'tripBeendet':
        _ref.read(aktuellerTripIdProvider.notifier).state = null;
        _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;

      case 'position':
        final lat = (daten['lat'] as num).toDouble();
        final lng = (daten['lng'] as num).toDouble();
        final speed = (daten['speed'] as num?)?.toDouble() ?? 0.0;
        _ref.read(aktuellePositionProvider.notifier).state = (lat: lat, lng: lng, speed: speed);
        _ortAktualisieren(lat, lng);
    }
  }

  DateTime? _letzteOrtAbfrage;

  void _ortAktualisieren(double lat, double lng) async {
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
