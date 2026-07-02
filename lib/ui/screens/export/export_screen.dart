import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions.dart';
import '../../../l10n/app_de.dart';
import '../../../providers/trip_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../../../services/export_service.dart';
import '../../shared/loading_indicator.dart';
import 'widgets/export_format_selector.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String? _selectedVehicleId;
  late DateTime _von;
  late DateTime _bis;
  ExportFormat _format = ExportFormat.pdf;
  bool _exportiert = false;

  @override
  void initState() {
    super.initState();
    final jetzt = DateTime.now();
    _von = DateTime(jetzt.year, 1, 1);
    _bis = jetzt;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = ref.watch(vehiclesProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppDe.exportTitel)),
      body: vehicles.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('$e')),
        data: (vehicleList) {
          if (vehicleList.isEmpty) {
            return const Center(child: Text(AppDe.keinFahrzeug));
          }

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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Fahrzeug
              DropdownButtonFormField<String>(
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
                onChanged: (id) =>
                    setState(() => _selectedVehicleId = id),
              ),
              const SizedBox(height: 16),

              // Zeitraum
              Text(
                AppDe.zeitraumWaehlen,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _von,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _von = d);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_von.datumFormatiert),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _bis,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => _bis = d);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_bis.datumFormatiert),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Schnellauswahl
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text('${DateTime.now().year}'),
                    onPressed: () {
                      final j = DateTime.now().year;
                      setState(() {
                        _von = DateTime(j, 1, 1);
                        _bis = DateTime.now();
                      });
                    },
                  ),
                  ActionChip(
                    label: Text('${DateTime.now().year - 1}'),
                    onPressed: () {
                      final j = DateTime.now().year - 1;
                      setState(() {
                        _von = DateTime(j, 1, 1);
                        _bis = DateTime(j, 12, 31);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Format
              ExportFormatSelector(
                selected: _format,
                onChanged: (f) => setState(() => _format = f),
              ),
              const SizedBox(height: 24),

              // Vorschau
              trips.when(
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('$e'),
                data: (liste) {
                  final gesamtKm = liste.fold<double>(
                      0.0, (s, t) => s + t.distanceKm);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Anzahl Fahrten:'),
                              Text('${liste.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Gesamtkilometer:'),
                              Text(gesamtKm.kmFormatiert,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Export-Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _exportiert
                      ? null
                      : () => _exportieren(vehicleId, vehicleList),
                  icon: const Icon(Icons.share),
                  label: Text(
                    _exportiert
                        ? AppDe.exportErfolgreich
                        : AppDe.exportieren,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportieren(
    String vehicleId,
    List vehicleList,
  ) async {
    final vehicle =
        vehicleList.firstWhere((v) => v.id == vehicleId);
    final filter =
        TripsFilter(vehicleId: vehicleId, von: _von, bis: _bis);
    final trips = await ref.read(tripsProvider(filter).future);

    if (trips.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Fahrten im gewählten Zeitraum.')),
        );
      }
      return;
    }

    final datei = _format == ExportFormat.csv
        ? await ExportService.csvErstellen(vehicle, trips, _von, _bis)
        : await ExportService.pdfErstellen(vehicle, trips, _von, _bis);

    await ExportService.teilen(datei);

    if (mounted) {
      setState(() => _exportiert = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _exportiert = false);
      });
    }
  }
}
