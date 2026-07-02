import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import '../../../l10n/app_de.dart';
import '../../../providers/statistics_providers.dart';
import '../../../providers/tracking_providers.dart';
import '../../../data/models/vehicle.dart';
import '../../../providers/vehicle_providers.dart';
import '../../../core/utils/haversine.dart';
import '../../shared/loading_indicator.dart';
import 'widgets/active_vehicle_card.dart';
import 'widgets/km_progress_card.dart';
import 'kilometerstand_dialog.dart';
import 'widgets/live_location_card.dart';
import 'widgets/tracking_status_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  StreamSubscription<Position>? _positionSub;
  bool _streamLaeuft = false;
  Position? _vorherigeStreamPos;
  DateTime? _vorherigeStreamZeit;

  @override
  void initState() {
    super.initState();
    _standortBerechtigung();
  }

  Future<void> _standortBerechtigung() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always) return;

    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(AppDe.berechtigungTitel),
          content: const Text(AppDe.berechtigungErklaerung),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppDe.verstanden),
            ),
          ],
        ),
      );

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always && mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hintergrund-Standort benötigt'),
          content: const Text(
            'Damit die Kilometererfassung auch bei gesperrtem Bildschirm '
            'funktioniert, muss der Standortzugriff auf "Immer" gesetzt werden.\n\n'
            'Gehe zu:\nEinstellungen > Drivio > Standort > Immer',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Später'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Einstellungen öffnen'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  /// Plattformspezifische Einstellungen:
  /// - iOS: Hintergrund-Updates erlauben, sonst stoppt GPS bei gesperrtem
  ///   Bildschirm. distanceFilter 0, damit auch im Stillstand Updates
  ///   kommen (nötig für die automatische Fahrtende-Erkennung).
  LocationSettings _locationSettings() {
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 3),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  void _positionStreamVerwalten(bool serviceAktiv) {
    if (serviceAktiv && !_streamLaeuft) {
      _streamLaeuft = true;
      _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: _locationSettings(),
      ).listen(_onPosition, onError: (_) {});
    } else if (!serviceAktiv && _streamLaeuft) {
      _streamLaeuft = false;
      _positionSub?.cancel();
      _positionSub = null;
      _vorherigeStreamPos = null;
      _vorherigeStreamZeit = null;
    }
  }

  void _onPosition(Position pos) {
    double speedMs = pos.speed;
    if (speedMs < 0 && _vorherigeStreamPos != null && _vorherigeStreamZeit != null) {
      final distanzKm = haversineKm(
        _vorherigeStreamPos!.latitude,
        _vorherigeStreamPos!.longitude,
        pos.latitude,
        pos.longitude,
      );
      final zeitSek =
          DateTime.now().difference(_vorherigeStreamZeit!).inMilliseconds / 1000.0;
      if (zeitSek > 0) {
        speedMs = (distanzKm * 1000) / zeitSek;
      } else {
        speedMs = 0;
      }
    } else if (speedMs < 0) {
      speedMs = 0;
    }
    _vorherigeStreamPos = pos;
    _vorherigeStreamZeit = DateTime.now();

    ref.read(aktuellePositionProvider.notifier).state = (
      lat: pos.latitude,
      lng: pos.longitude,
      speed: speedMs,
    );

    final controller = ref.read(trackingControllerProvider);
    controller.positionVerarbeiten(pos);
    controller.ortAktualisieren(pos.latitude, pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final serviceAktiv = ref.watch(serviceAktivProvider);
    final zustand = ref.watch(trackingZustandProvider);
    final distanz = ref.watch(aktuelleDistanzProvider);
    final position = ref.watch(aktuellePositionProvider);
    final ortsname = ref.watch(aktuellerOrtProvider);

    _positionStreamVerwalten(serviceAktiv);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/via-lab-logo.svg',
              height: 22,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            const Text(AppDe.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: activeVehicle.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('${AppDe.fehler}: $e')),
        data: (vehicle) {
          final jahr = DateTime.now().year;
          final jahresKm = vehicle != null
              ? ref.watch(jahresKmProvider(
                  JahresKmParams(vehicleId: vehicle.id, jahr: jahr)))
              : null;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeVehicleProvider);
              ref.invalidate(vehiclesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ActiveVehicleCard(
                  vehicle: vehicle,
                  onWechseln: () => _fahrzeugWaehlen(context),
                ),
                const SizedBox(height: 12),
                if (vehicle != null) ...[
                  TrackingStatusCard(
                    serviceAktiv: serviceAktiv,
                    zustand: zustand,
                    aktuelleDistanzKm: distanz,
                    onStartenStoppen: () => _erfassungToggle(vehicle),
                    onFahrtManuellStarten: () =>
                        ref.read(trackingControllerProvider).manuellStarten(),
                    onFahrtStoppen: () =>
                        ref.read(trackingControllerProvider).manuellStoppen(),
                  ),
                  if (serviceAktiv && position != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: LiveLocationCard(
                        lat: position.lat,
                        lng: position.lng,
                        speedKmh: position.speed * 3.6,
                        ortsname: ortsname,
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (jahresKm != null)
                    jahresKm.when(
                      loading: () => const LoadingIndicator(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (km) => KmProgressCard(
                        aktuelleKm: km,
                        limitKm: vehicle.jahresLimitKm,
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _erfassungToggle(Vehicle vehicle) async {
    final controller = ref.read(trackingControllerProvider);
    final aktiv = ref.read(serviceAktivProvider);
    if (aktiv) {
      controller.stoppen();
      return;
    }

    if (!mounted) return;
    final ergebnis = await KilometerstandDialog.zeigen(
      context,
      aktuellerStand: vehicle.kilometerstand,
      fahrzeugName: vehicle.name,
      istFirmenwagen: vehicle.istFirmenwagen,
    );
    if (ergebnis == null) return;

    await ref.read(vehiclesProvider.notifier).kilometerstandAktualisieren(
      vehicle.id,
      ergebnis.kilometerstand,
    );

    final gestartet = await controller.starten(
      vehicle.id,
      vehicle.name,
      istFirmenfahrt: ergebnis.istFirmenfahrt,
      kilometerstandStart: ergebnis.kilometerstand,
    );
    if (!gestartet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erfassung konnte nicht gestartet werden. '
            'Bitte Standort-Berechtigung prüfen.',
          ),
        ),
      );
    }
  }

  void _fahrzeugWaehlen(BuildContext context) {
    final vehicles = ref.read(vehiclesProvider);
    vehicles.whenData((liste) {
      if (liste.isEmpty) return;
      showModalBottomSheet(
        context: context,
        builder: (context) => ListView.builder(
          shrinkWrap: true,
          itemCount: liste.length,
          itemBuilder: (context, index) {
            final v = liste[index];
            return ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text(v.name),
              subtitle: Text(v.kennzeichen),
              trailing: v.aktiv ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                ref.read(vehiclesProvider.notifier).aktivSetzen(v.id);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      );
    });
  }
}
