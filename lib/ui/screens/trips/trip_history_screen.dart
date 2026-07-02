import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions.dart';
import '../../../data/models/trip.dart';
import '../../../l10n/app_de.dart';
import '../../../providers/trip_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../../shared/confirmation_dialog.dart';
import '../../shared/loading_indicator.dart';
import 'trip_form_screen.dart';
import 'trip_map_screen.dart';
import 'widgets/date_range_filter.dart';
import 'widgets/trip_list_tile.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

/// Filter für den Fahrttyp in der Fahrtenliste.
enum FahrtTypFilter { alle, privat, firma }

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  String? _selectedVehicleId;
  DateTime? _von;
  DateTime? _bis;
  FahrtTypFilter _typFilter = FahrtTypFilter.alle;

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

          // Standard: aktives Fahrzeug (validiert gegen die Liste)
          final ids = vehicleList.map((v) => v.id).toSet();
          final kandidat = _selectedVehicleId ?? activeVehicle.value?.id;
          final vehicleId = (kandidat != null && ids.contains(kandidat))
              ? kandidat
              : vehicleList.first.id;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<FahrtTypFilter>(
                  segments: const [
                    ButtonSegment(
                      value: FahrtTypFilter.alle,
                      label: Text('Alle'),
                    ),
                    ButtonSegment(
                      value: FahrtTypFilter.privat,
                      label: Text('Privat'),
                      icon: Icon(Icons.home, size: 18),
                    ),
                    ButtonSegment(
                      value: FahrtTypFilter.firma,
                      label: Text('Firma'),
                      icon: Icon(Icons.business_center, size: 18),
                    ),
                  ],
                  selected: {_typFilter},
                  onSelectionChanged: (auswahl) {
                    setState(() => _typFilter = auswahl.first);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: trips.when(
                  loading: () => const LoadingIndicator(),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (alleTrips) {
                    final liste = switch (_typFilter) {
                      FahrtTypFilter.alle => alleTrips,
                      FahrtTypFilter.privat =>
                        alleTrips.where((t) => !t.istFirmenfahrt).toList(),
                      FahrtTypFilter.firma =>
                        alleTrips.where((t) => t.istFirmenfahrt).toList(),
                    };
                    if (liste.isEmpty) {
                      // Unterscheiden: gar keine Fahrten vs. nur weggefiltert
                      final nurGefiltert = alleTrips.isNotEmpty;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.route_outlined, size: 64),
                              const SizedBox(height: 16),
                              Text(nurGefiltert
                                  ? (_typFilter == FahrtTypFilter.firma
                                      ? 'Keine Firmenfahrten'
                                      : 'Keine Privatfahrten')
                                  : AppDe.keinefahrten),
                              const SizedBox(height: 8),
                              Text(
                                nurGefiltert
                                    ? 'Für diesen Filter gibt es keine Fahrten. '
                                        'Tippe auf "Alle", um alle Fahrten zu sehen.'
                                    : AppDe.keinefahrtenInfo,
                                textAlign: TextAlign.center,
                              ),
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
                                onTap: () => _karteZeigen(context, trip),
                                onBearbeiten: () => _bearbeiten(
                                    context, trip.id, vehicleId),
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
        heroTag: 'fab_fahrt_hinzufuegen',
        onPressed: () {
          final vehicleId = _selectedVehicleId ??
              ref.read(activeVehicleProvider).value?.id;
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

  void _karteZeigen(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripMapScreen(trip: trip),
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
