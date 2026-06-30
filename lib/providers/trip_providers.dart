import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/trip.dart';
import '../data/repositories/trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

/// Parameter für Fahrten-Abfrage.
class TripsFilter {
  final String vehicleId;
  final DateTime? von;
  final DateTime? bis;

  const TripsFilter({required this.vehicleId, this.von, this.bis});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripsFilter &&
          vehicleId == other.vehicleId &&
          von == other.von &&
          bis == other.bis;

  @override
  int get hashCode => Object.hash(vehicleId, von, bis);
}

/// Fahrten für ein bestimmtes Fahrzeug, optional mit Zeitraum-Filter.
final tripsProvider =
    FutureProvider.family<List<Trip>, TripsFilter>((ref, filter) async {
  final repo = ref.read(tripRepositoryProvider);
  return repo.fuerFahrzeug(
    filter.vehicleId,
    von: filter.von,
    bis: filter.bis,
  );
});

/// Notifier für Trip-CRUD-Operationen.
final tripCrudProvider = Provider<TripCrud>((ref) => TripCrud(ref));

class TripCrud {
  final Ref _ref;

  TripCrud(this._ref);

  Future<void> manuellErstellen({
    required String vehicleId,
    required DateTime startTimestamp,
    required DateTime endTimestamp,
    required double distanceKm,
    String? notiz,
  }) async {
    final repo = _ref.read(tripRepositoryProvider);
    final trip = Trip(
      id: const Uuid().v4(),
      vehicleId: vehicleId,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp,
      distanceKm: distanceKm,
      manuellErfasst: true,
      notiz: notiz,
    );
    await repo.einfuegen(trip);
    _ref.invalidate(tripsProvider);
  }

  Future<void> aktualisieren(Trip trip) async {
    final repo = _ref.read(tripRepositoryProvider);
    await repo.aktualisieren(trip);
    _ref.invalidate(tripsProvider);
  }

  Future<void> loeschen(String id) async {
    final repo = _ref.read(tripRepositoryProvider);
    await repo.loeschen(id);
    _ref.invalidate(tripsProvider);
  }
}
