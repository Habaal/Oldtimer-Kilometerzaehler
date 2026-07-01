import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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
        eventAction: ForegroundTaskEventAction.repeat(30000),
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

  static void notificationAktualisieren(String text) {
    FlutterForegroundTask.updateService(notificationText: text);
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveTaskHandler());
}

class _KeepAliveTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
