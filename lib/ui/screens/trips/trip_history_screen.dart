import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions.dart';
import '../../../l10n/app_de.dart';
import '../../../providers/trip_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../../shared/confirmation_dialog.dart';
import '../../shared/loading_indicator.dart';
import 'trip_form_screen.dart';
import 'widgets/date_range_filter.dart';
import 'widgets/trip_list_tile.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  String? _selectedVehicleId;
  DateTime? _von;
  DateTime? _bis;

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppDe.fahrten)),
      body: vehicles.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('$e')),
        data: (vehicleList) {
          if (vehicleList.isEmpty) {
            return const Center(
              child: Text(AppDe.keinFahrzeug),
            );
          }

          // Standard: aktives Fahrzeug
          final vehicleId = _selectedVehicleId ??
              activeVehicle.valueOrNull?.id ??
              vehicleList.first.id;

          final filter = TripsFilter(
            vehicleId: vehicleId,
            von: _von,
            bis: _bis,
          );
          final trips = ref.watch(tripsProvider(filter));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DropdownButtonFormField<String>(
                  value: vehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Fahrzeug',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: vehicleList.map((v) {
                    return DropdownMenuItem(
                      value: v.id,
                      child: Text('${v.name} (${v.kennzeichen})'),
                    );
                  }).toList(),
                  onChanged: (id) => setState(() => _selectedVehicleId = id),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DateRangeFilter(
                  von: _von,
                  bis: _bis,
                  onChanged: (range) {
                    setState(() {
                      _von = range?.start;
                      _bis = range?.end;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: trips.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (liste) {
                    if (liste.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_outlined, size: 64),
                              SizedBox(height: 16),
                              Text(AppDe.keinefahrten),
                              SizedBox(height: 8),
                              Text(AppDe.keinefahrtenInfo,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }

                    // Gesamtkilometer oben anzeigen
                    final gesamtKm =
                        liste.fold<double>(0.0, (s, t) => s + t.distanceKm);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${liste.length} Fahrten'),
                              Text(
                                'Gesamt: ${gesamtKm.kmFormatiert}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: liste.length,
                            itemBuilder: (context, index) {
                              final trip = liste[index];
                              return TripListTile(
                                trip: trip,
                                onTap: () => _bearbeiten(context, trip.id,
                                    vehicleId),
                                onLoeschen: () async {
                                  final ok = await bestaetigenDialog(
                                    context,
                                    titel: AppDe.loeschen,
                                    nachricht:
                                        AppDe.fahrtLoeschenBestaetigung,
                                  );
                                  if (ok) {
                                    ref
                                        .read(tripCrudProvider)
                                        .loeschen(trip.id);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final vehicleId = _selectedVehicleId ??
              ref.read(activeVehicleProvider).valueOrNull?.id;
          if (vehicleId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TripFormScreen(vehicleId: vehicleId),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _bearbeiten(BuildContext context, String tripId, String vehicleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TripFormScreen(vehicleId: vehicleId, tripId: tripId),
      ),
    );
  }
}
