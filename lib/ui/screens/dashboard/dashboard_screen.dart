import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_de.dart';
import '../../../providers/statistics_providers.dart';
import '../../../providers/tracking_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../../shared/loading_indicator.dart';
import 'widgets/active_vehicle_card.dart';
import 'widgets/km_progress_card.dart';
import 'widgets/tracking_status_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onTaskDaten);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskDaten);
    super.dispose();
  }

  void _onTaskDaten(Object data) {
    if (data is Map<String, dynamic>) {
      ref.read(trackingControllerProvider).datenVerarbeiten(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleProvider);
    final serviceAktiv = ref.watch(serviceAktivProvider);
    final zustand = ref.watch(trackingZustandProvider);
    final distanz = ref.watch(aktuelleDistanzProvider);
    final vehicles = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppDe.appName),
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
                    onStartenStoppen: () => _erfassungToggle(vehicle.id, vehicle.name),
                    onFahrtManuellStarten: () =>
                        ref.read(trackingControllerProvider).manuellStarten(),
                    onFahrtStoppen: () =>
                        ref.read(trackingControllerProvider).manuellStoppen(),
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

  void _erfassungToggle(String vehicleId, String fahrzeugName) {
    final controller = ref.read(trackingControllerProvider);
    final aktiv = ref.read(serviceAktivProvider);
    if (aktiv) {
      controller.stoppen();
    } else {
      controller.starten(vehicleId, fahrzeugName);
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
