import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/foreground_task_service.dart';
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

final trackingControllerProvider =
    Provider<TrackingController>((ref) => TrackingController(ref));

class TrackingController {
  final Ref _ref;

  TrackingController(this._ref);

  Future<void> starten(String vehicleId, String fahrzeugName) async {
    ForegroundTaskService.init();
    final gestartet = await ForegroundTaskService.starten(fahrzeugName);
    if (gestartet) {
      _ref.read(serviceAktivProvider.notifier).state = true;
      ForegroundTaskService.datenAnTaskSenden({'vehicleId': vehicleId});
    }
  }

  Future<void> stoppen() async {
    await ForegroundTaskService.stoppen();
    _ref.read(serviceAktivProvider.notifier).state = false;
    _ref.read(trackingZustandProvider.notifier).state = TrackingZustand.idle;
    _ref.read(aktuelleDistanzProvider.notifier).state = 0.0;
    _ref.read(aktuellerTripIdProvider.notifier).state = null;
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
    }
  }
}
