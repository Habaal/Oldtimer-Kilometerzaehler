import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/wartung.dart';
import '../data/repositories/wartung_repository.dart';

final wartungRepositoryProvider = Provider<WartungRepository>((ref) {
  return WartungRepository();
});

/// Wartungseinträge für ein Fahrzeug, neueste zuerst.
final wartungenProvider =
    FutureProvider.family<List<Wartung>, String>((ref, vehicleId) async {
  final repo = ref.read(wartungRepositoryProvider);
  return repo.fuerFahrzeug(vehicleId);
});

final wartungCrudProvider = Provider<WartungCrud>((ref) => WartungCrud(ref));

class WartungCrud {
  final Ref _ref;

  WartungCrud(this._ref);

  Future<void> erstellen({
    required String vehicleId,
    required WartungTyp typ,
    required DateTime datum,
    double? kilometerstand,
    String? notiz,
  }) async {
    final repo = _ref.read(wartungRepositoryProvider);
    await repo.einfuegen(Wartung(
      id: const Uuid().v4(),
      vehicleId: vehicleId,
      typ: typ,
      datum: datum,
      kilometerstand: kilometerstand,
      notiz: notiz,
    ));
    _ref.invalidate(wartungenProvider);
  }

  Future<void> loeschen(String id) async {
    final repo = _ref.read(wartungRepositoryProvider);
    await repo.loeschen(id);
    _ref.invalidate(wartungenProvider);
  }
}
