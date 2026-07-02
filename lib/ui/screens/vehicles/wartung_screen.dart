import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/models/wartung.dart';
import '../../../providers/wartung_providers.dart';
import '../../shared/confirmation_dialog.dart';
import '../../shared/loading_indicator.dart';

IconData wartungIcon(WartungTyp typ) {
  switch (typ) {
    case WartungTyp.oelwechsel:
    case WartungTyp.oelstand:
      return Icons.oil_barrel;
    case WartungTyp.reifenwechsel:
    case WartungTyp.reifendruck:
      return Icons.tire_repair;
    case WartungTyp.service:
      return Icons.build;
    case WartungTyp.reparatur:
      return Icons.handyman;
    case WartungTyp.pickerl:
      return Icons.verified;
    case WartungTyp.batterie:
      return Icons.battery_charging_full;
    case WartungTyp.sonstiges:
      return Icons.note_alt;
  }
}

class WartungScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const WartungScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wartungen = ref.watch(wartungenProvider(vehicle.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Wartung – ${vehicle.name}'),
      ),
      body: wartungen.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('$e')),
        data: (liste) {
          if (liste.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.build_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Noch keine Wartungseinträge',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trage Ölstand, Reifenwechsel, Service und mehr ein,\n'
                      'um den Überblick über dein Fahrzeug zu behalten.',
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
              final wartung = liste[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      wartungIcon(wartung.typ),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(wartung.typ.anzeigeName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wartung.datum.datumFormatiert),
                      if (wartung.kilometerstand != null)
                        Text(
                          'bei ${wartung.kilometerstand!.toStringAsFixed(0)} km',
                        ),
                      if (wartung.notiz != null && wartung.notiz!.isNotEmpty)
                        Text(
                          wartung.notiz!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine:
                      wartung.notiz != null && wartung.notiz!.isNotEmpty,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await bestaetigenDialog(
                        context,
                        titel: 'Löschen',
                        nachricht: 'Diesen Wartungseintrag löschen?',
                      );
                      if (ok) {
                        ref.read(wartungCrudProvider).loeschen(wartung.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_wartung_hinzufuegen',
        onPressed: () => _eintragHinzufuegen(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _eintragHinzufuegen(BuildContext context, WidgetRef ref) async {
    final ergebnis = await showModalBottomSheet<_WartungFormErgebnis>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WartungForm(
        aktuellerKilometerstand: vehicle.kilometerstand,
      ),
    );
    if (ergebnis == null) return;

    await ref.read(wartungCrudProvider).erstellen(
          vehicleId: vehicle.id,
          typ: ergebnis.typ,
          datum: ergebnis.datum,
          kilometerstand: ergebnis.kilometerstand,
          notiz: ergebnis.notiz,
        );
  }
}

class _WartungFormErgebnis {
  final WartungTyp typ;
  final DateTime datum;
  final double? kilometerstand;
  final String? notiz;

  const _WartungFormErgebnis({
    required this.typ,
    required this.datum,
    this.kilometerstand,
    this.notiz,
  });
}

class _WartungForm extends StatefulWidget {
  final double? aktuellerKilometerstand;

  const _WartungForm({this.aktuellerKilometerstand});

  @override
  State<_WartungForm> createState() => _WartungFormState();
}

class _WartungFormState extends State<_WartungForm> {
  WartungTyp _typ = WartungTyp.oelstand;
  DateTime _datum = DateTime.now();
  late final TextEditingController _kmController;
  final _notizController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(
      text: widget.aktuellerKilometerstand?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    _notizController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Wartungseintrag',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<WartungTyp>(
            value: _typ,
            decoration: const InputDecoration(
              labelText: 'Typ',
              border: OutlineInputBorder(),
            ),
            items: WartungTyp.values.map((t) {
              return DropdownMenuItem(
                value: t,
                child: Row(
                  children: [
                    Icon(wartungIcon(t), size: 20),
                    const SizedBox(width: 8),
                    Text(t.anzeigeName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (t) => setState(() => _typ = t!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(_datum.datumFormatiert),
            onPressed: () async {
              final gewaehlt = await showDatePicker(
                context: context,
                initialDate: _datum,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                locale: const Locale('de', 'DE'),
              );
              if (gewaehlt != null) {
                setState(() => _datum = gewaehlt);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kmController,
            decoration: const InputDecoration(
              labelText: 'Kilometerstand (optional)',
              suffixText: 'km',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notizController,
            decoration: const InputDecoration(
              labelText: 'Notiz (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Speichern'),
            onPressed: () {
              final km = double.tryParse(_kmController.text.trim());
              final notiz = _notizController.text.trim();
              Navigator.of(context).pop(_WartungFormErgebnis(
                typ: _typ,
                datum: _datum,
                kilometerstand: km,
                notiz: notiz.isEmpty ? null : notiz,
              ));
            },
          ),
        ],
      ),
    );
  }
}
