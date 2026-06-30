import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/foreground_task_service.dart';
import '../services/trip_detection_service.dart';

/// Aktueller Tracking-Zustand.
final trackingZustandProvider =
    StateProvider<TrackingZustand>((ref) => TrackingZustand.idle);

/// Ob der Foreground-Service gerade läuft.
final serviceAktivProvider = StateProvider<bool>((ref) => false);

/// Aktuelle Distanz des laufenden Trips (in km).
final aktuelleDistanzProvider = StateProvider<double>((ref) => 0.0);

/// Aktuelle Trip-ID (wenn Trip läuft).
final aktuellerTripIdProvider = StateProvider<String?>((ref) => null);

/// Controller für Tracking-Aktionen.
final trackingControllerProvider =
    Provider<TrackingController>((ref) => TrackingController(ref));

class TrackingController {
  final Ref _ref;

  TrackingController(this._ref);

  /// Startet den Tracking-Service für ein Fahrzeug.
  Future<void> starten(String vehicleId, String fahrzeugName) async {
    ForegroundTaskService.init();
    final gestartet = await ForegroundTaskService.starten(fahrzeugName);
    if (gestartet) {
      _ref.read(serviceAktivProvider.notifier).state = true;
      ForegroundTaskService.datenAnTaskSenden({'vehicleId': vehicleId});
    }
  }

  /// Stoppt den Tracking-Service.
  Future<void> stoppen() async {
    await ForegroundTaskService.stoppen();
    _ref.read(serviceAktivProvider.notifier).state = false;
    _ref.read(trackingZustandProvider.notifier).state = TrackingZustand.idle;
    _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;
    _ref.read(aktuellerTripIdProvider.notifier).state = null;
  }

  /// Startet einen Trip manuell.
  void manuellStarten() {
    ForegroundTaskService.datenAnTaskSenden({'action': 'manuellStarten'});
  }

  /// Stoppt den aktuellen Trip manuell.
  void manuellStoppen() {
    ForegroundTaskService.datenAnTaskSenden({'action': 'manuellStoppen'});
  }

  /// Verarbeitet Daten vom TaskHandler (aufgerufen in der UI).
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
    }
  }
}
