import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/vehicle.dart';
import '../data/repositories/vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});

/// Alle Fahrzeuge aus der Datenbank.
final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(VehiclesNotifier.new);

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    final repo = ref.read(vehicleRepositoryProvider);
    return repo.alleAbrufen();
  }

  Future<void> erstellen({
    required String name,
    required String kennzeichen,
    required int baujahr,
    double? jahresLimitKm,
    String? fotoPath,
  }) async {
    final repo = ref.read(vehicleRepositoryProvider);
    final jetzt = DateTime.now();
    final vehicle = Vehicle(
      id: const Uuid().v4(),
      name: name,
      kennzeichen: kennzeichen,
      baujahr: baujahr,
      jahresLimitKm: jahresLimitKm,
      fotoPath: fotoPath,
      erstelltAm: jetzt,
      aktualisiertAm: jetzt,
    );
    await repo.einfuegen(vehicle);
    ref.invalidateSelf();
  }

  Future<void> aktualisieren(Vehicle vehicle) async {
    final repo = ref.read(vehicleRepositoryProvider);
    await repo.aktualisieren(
      vehicle.copyWith(aktualisiertAm: DateTime.now()),
    );
    ref.invalidateSelf();
    ref.invalidate(activeVehicleProvider);
  }

  Future<void> loeschen(String id) async {
    final repo = ref.read(vehicleRepositoryProvider);
    await repo.loeschen(id);
    ref.invalidateSelf();
    ref.invalidate(activeVehicleProvider);
  }

  Future<void> aktivSetzen(String id) async {
    final repo = ref.read(vehicleRepositoryProvider);
    await repo.aktivSetzen(id);
    ref.invalidateSelf();
    ref.invalidate(activeVehicleProvider);
  }
}

/// Das aktuell aktive Fahrzeug.
final activeVehicleProvider = FutureProvider<Vehicle?>((ref) async {
  final repo = ref.read(vehicleRepositoryProvider);
  return repo.aktivesAbrufen();
});
