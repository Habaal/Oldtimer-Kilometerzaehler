import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/trip_repository.dart';
import 'trip_providers.dart';

/// Parameter für Jahres-KM-Abfrage.
class JahresKmParams {
  final String vehicleId;
  final int jahr;

  const JahresKmParams({required this.vehicleId, required this.jahr});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JahresKmParams &&
          vehicleId == other.vehicleId &&
          jahr == other.jahr;

  @override
  int get hashCode => Object.hash(vehicleId, jahr);
}

/// Gesamtkilometer für ein Fahrzeug in einem bestimmten Jahr.
final jahresKmProvider =
    FutureProvider.family<double, JahresKmParams>((ref, params) async {
  final repo = ref.read(tripRepositoryProvider);
  return repo.gesamtKm(
    params.vehicleId,
    von: DateTime(params.jahr, 1, 1),
    bis: DateTime(params.jahr, 12, 31, 23, 59, 59),
  );
});

/// Kilometer pro Monat für ein Fahrzeug in einem bestimmten Jahr.
final monatsKmProvider =
    FutureProvider.family<Map<int, double>, JahresKmParams>((ref, params) async {
  final repo = ref.read(tripRepositoryProvider);
  return repo.monatsKm(params.vehicleId, params.jahr);
});

/// Gesamtkilometer über alle Jahre.
final gesamtKmProvider =
    FutureProvider.family<double, String>((ref, vehicleId) async {
  final repo = ref.read(tripRepositoryProvider);
  return repo.gesamtKm(vehicleId);
});
