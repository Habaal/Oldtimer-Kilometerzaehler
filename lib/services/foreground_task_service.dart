import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import 'trip_detection_service.dart';

class ForegroundTaskService {
  ForegroundTaskService._();

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'km_tracking_channel',
        channelName: 'KM-Erfassung',
        channelDescription: 'Kilometerzähler läuft im Hintergrund',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> starten(String fahrzeugName) async {
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'KM-Erfassung aktiv',
        notificationText: 'Erfassung für $fahrzeugName',
        callback: _startCallback,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stoppen() async {
    try {
      await FlutterForegroundTask.stopService();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> laeuft() async {
    return FlutterForegroundTask.isRunningService;
  }

  /// Sendet Daten an den TaskHandler (z.B. aktive vehicleId).
  static void datenAnTaskSenden(Map<String, dynamic> daten) {
    FlutterForegroundTask.sendDataToTask(daten);
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(KmTrackingTaskHandler());
}

/// Hauptlogik des Hintergrund-Tracking-Dienstes.
/// Wird vom Foreground Service aufgerufen, läuft auch bei gesperrtem Bildschirm.
class KmTrackingTaskHandler extends TaskHandler {
  TripDetectionService? _tripDetection;
  String? _vehicleId;
  DateTime? _letzteGpsAbfrage;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _tripDetection = TripDetectionService(
      onZustandGeaendert: (zustand) {
        FlutterForegroundTask.sendDataToMain({
          'type': 'zustand',
          'zustand': zustand.name,
        });
      },
      onDistanzAktualisiert: (tripId, distanz) {
        FlutterForegroundTask.updateService(
          notificationText:
              'Fahrt aktiv – ${distanz.toStringAsFixed(1)} km',
        );
        FlutterForegroundTask.sendDataToMain({
          'type': 'distanz',
          'tripId': tripId,
          'distanzKm': distanz,
        });
      },
      onTripGestartet: (tripId) {
        FlutterForegroundTask.sendDataToMain({
          'type': 'tripGestartet',
          'tripId': tripId,
        });
      },
      onTripBeendet: (tripId, gesamtKm) {
        FlutterForegroundTask.sendDataToMain({
          'type': 'tripBeendet',
          'tripId': tripId,
          'gesamtKm': gesamtKm,
        });
      },
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_tripDetection == null) return;

    // GPS-Intervall je nach Zustand anpassen
    final intervall = _gpsIntervall();
    if (_letzteGpsAbfrage != null &&
        timestamp.difference(_letzteGpsAbfrage!) < intervall) {
      return;
    }
    _letzteGpsAbfrage = timestamp;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: _gpsGenauigkeit(),
        ),
      );
      await _tripDetection!.positionVerarbeiten(position);
    } catch (_) {}
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('vehicleId')) {
        _vehicleId = data['vehicleId'] as String?;
      }
      if (data['action'] == 'manuellStarten' && _vehicleId != null) {
        _manuellStarten();
      }
      if (data['action'] == 'manuellStoppen') {
        _tripDetection?.manuellStoppen();
      }
    }
  }

  Future<void> _manuellStarten() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _tripDetection?.manuellStarten(_vehicleId!, position);
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _tripDetection?.erzwungenStoppen();
  }

  Duration _gpsIntervall() {
    switch (_tripDetection?.zustand) {
      case TrackingZustand.idle:
        return TrackingConstants.idleGpsInterval;
      case TrackingZustand.detecting:
        return TrackingConstants.detectingGpsInterval;
      case TrackingZustand.tripActive:
        return TrackingConstants.activeGpsInterval;
      case TrackingZustand.stopping:
        return TrackingConstants.stoppingGpsInterval;
      case null:
        return TrackingConstants.idleGpsInterval;
    }
  }

  LocationAccuracy _gpsGenauigkeit() {
    switch (_tripDetection?.zustand) {
      case TrackingZustand.idle:
        return LocationAccuracy.low;
      case TrackingZustand.detecting:
      case TrackingZustand.tripActive:
        return LocationAccuracy.high;
      case TrackingZustand.stopping:
        return LocationAccuracy.medium;
      case null:
        return LocationAccuracy.low;
    }
  }
}
