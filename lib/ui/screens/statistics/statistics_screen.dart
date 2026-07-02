import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_de.dart';
import '../../../providers/statistics_providers.dart';
import '../../../providers/vehicle_providers.dart';
import '../../shared/loading_indicator.dart';
import 'sachbezug_screen.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/year_comparison_card.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String? _selectedVehicleId;
  late int _jahr;

  @override
  void initState() {
    super.initState();
    _jahr = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = ref.watch(vehiclesProvider);
    final activeVehicle = ref.watch(activeVehicleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppDe.statistik)),
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

          final vehicle = vehicleList.firstWhere((v) => v.id == vehicleId);

          final diesesJahrKm = ref.watch(jahresKmProvider(
            JahresKmParams(vehicleId: vehicleId, jahr: _jahr),
          ));
          final letztesJahrKm = ref.watch(jahresKmProvider(
            JahresKmParams(vehicleId: vehicleId, jahr: _jahr - 1),
          ));
          final gesamtKm = ref.watch(gesamtKmProvider(vehicleId));
          final monatsKm = ref.watch(monatsKmProvider(
            JahresKmParams(vehicleId: vehicleId, jahr: _jahr),
          ));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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

              // Sachbezugrechner (nur für Firmenwagen)
              if (vehicle.istFirmenwagen) ...[
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.business_center,
                          color: Colors.orange),
                    ),
                    title: const Text('Sachbezugrechner'),
                    subtitle: const Text(
                        'Monatlichen Sachbezug für die Privatnutzung berechnen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SachbezugScreen(vehicle: vehicle),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Jahresvergleich
              diesesJahrKm.when(
                loading: () => const LoadingIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (djKm) => letztesJahrKm.when(
                  loading: () => const LoadingIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (ljKm) => gesamtKm.when(
                    loading: () => const LoadingIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (gKm) => YearComparisonCard(
                      diesesJahrKm: djKm,
                      letztesJahrKm: ljKm,
                      gesamtKm: gKm,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Jahr-Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _jahr--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '$_jahr',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: _jahr < DateTime.now().year
                        ? () => setState(() => _jahr++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Monatsübersicht
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDe.monatsUebersicht,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      monatsKm.when(
                        loading: () => const LoadingIndicator(),
                        error: (_, __) => const Text('Fehler beim Laden'),
                        data: (daten) => MonthlyBarChart(
                          monatsKm: daten,
                          monatlichesZiel: vehicle.jahresLimitKm != null
                              ? vehicle.jahresLimitKm! / 12
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
