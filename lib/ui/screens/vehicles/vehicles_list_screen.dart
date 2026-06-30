import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_de.dart';
import '../../../providers/vehicle_providers.dart';
import '../../shared/confirmation_dialog.dart';
import '../../shared/loading_indicator.dart';
import 'vehicle_form_screen.dart';
import 'widgets/vehicle_list_tile.dart';

class VehiclesListScreen extends ConsumerWidget {
  const VehiclesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppDe.fahrzeuge)),
      body: vehicles.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('${AppDe.fehler}: $e')),
        data: (liste) {
          if (liste.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppDe.keinFahrzeug,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppDe.keinFahrzeugInfo,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final vehicle = liste[index];
              return VehicleListTile(
                vehicle: vehicle,
                onTap: () => _bearbeiten(context, vehicle.id),
                onAktivieren: () {
                  ref.read(vehiclesProvider.notifier).aktivSetzen(vehicle.id);
                },
                onLoeschen: () async {
                  final bestaetigt = await bestaetigenDialog(
                    context,
                    titel: AppDe.loeschen,
                    nachricht: AppDe.fahrzeugLoeschenBestaetigung,
                  );
                  if (bestaetigt) {
                    ref.read(vehiclesProvider.notifier).loeschen(vehicle.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _hinzufuegen(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _hinzufuegen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
    );
  }

  void _bearbeiten(BuildContext context, String vehicleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleFormScreen(vehicleId: vehicleId),
      ),
    );
  }
}
