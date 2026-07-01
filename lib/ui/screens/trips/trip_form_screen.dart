import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions.dart';
import '../../../data/models/trip.dart';
import '../../../l10n/app_de.dart';
import '../../../providers/trip_providers.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? tripId;

  const TripFormScreen({
    super.key,
    required this.vehicleId,
    this.tripId,
  });

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanzController = TextEditingController();
  final _notizController = TextEditingController();
  final _kmStartController = TextEditingController();
  final _kmEndeController = TextEditingController();

  late DateTime _datum;
  late TimeOfDay _startzeit;
  late TimeOfDay _endzeit;
  bool _istFirmenfahrt = false;
  bool _laden = false;
  bool _initialisiert = false;

  bool get _istBearbeitung => widget.tripId != null;

  @override
  void initState() {
    super.initState();
    _datum = DateTime.now();
    _startzeit = TimeOfDay.now();
    _endzeit = TimeOfDay.now();
  }

  @override
  void dispose() {
    _distanzController.dispose();
    _notizController.dispose();
    _kmStartController.dispose();
    _kmEndeController.dispose();
    super.dispose();
  }

  void _tripLaden(Trip trip) {
    if (_initialisiert) return;
    _initialisiert = true;
    _datum = trip.startTimestamp;
    _startzeit = TimeOfDay.fromDateTime(trip.startTimestamp);
    _endzeit = trip.endTimestamp != null
        ? TimeOfDay.fromDateTime(trip.endTimestamp!)
        : TimeOfDay.now();
    _distanzController.text = trip.distanceKm.toStringAsFixed(1);
    _notizController.text = trip.notiz ?? '';
    _istFirmenfahrt = trip.istFirmenfahrt;
    if (trip.kilometerstandStart != null) {
      _kmStartController.text = trip.kilometerstandStart!.toStringAsFixed(0);
    }
    if (trip.kilometerstandEnde != null) {
      _kmEndeController.text = trip.kilometerstandEnde!.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_istBearbeitung) {
      final filter = TripsFilter(vehicleId: widget.vehicleId);
      final trips = ref.watch(tripsProvider(filter));
      return trips.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
        data: (liste) {
          final trip = liste.where((t) => t.id == widget.tripId).firstOrNull;
          if (trip == null) {
            return const Scaffold(body: Center(child: Text('Fahrt nicht gefunden')));
          }
          _tripLaden(trip);
          return _buildForm(context, trip);
        },
      );
    }
    return _buildForm(context, null);
  }

  Widget _buildForm(BuildContext context, Trip? existing) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_istBearbeitung ? AppDe.fahrtBearbeiten : AppDe.fahrtHinzufuegen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Datum
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text(AppDe.datum),
                subtitle: Text(_datum.datumFormatiert),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _datum,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _datum = d);
                },
              ),
              const Divider(),

              // Startzeit
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text(AppDe.startzeit),
                subtitle: Text(_startzeit.format(context)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _startzeit,
                  );
                  if (t != null) setState(() => _startzeit = t);
                },
              ),
              const Divider(),

              // Endzeit
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text(AppDe.endzeit),
                subtitle: Text(_endzeit.format(context)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _endzeit,
                  );
                  if (t != null) setState(() => _endzeit = t);
                },
              ),
              const SizedBox(height: 16),

              // Distanz
              TextFormField(
                controller: _distanzController,
                decoration: const InputDecoration(
                  labelText: AppDe.distanz,
                  suffixText: 'km',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppDe.pflichtfeld;
                  final km = double.tryParse(v.replaceAll(',', '.'));
                  if (km == null || km <= 0) return 'Ungültige Distanz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notiz
              TextFormField(
                controller: _notizController,
                decoration: const InputDecoration(
                  labelText: AppDe.notiz,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kmStartController,
                      decoration: const InputDecoration(
                        labelText: 'KM-Stand Start',
                        suffixText: 'km',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _kmEndeController,
                      decoration: const InputDecoration(
                        labelText: 'KM-Stand Ende',
                        suffixText: 'km',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Firmenfahrt'),
                value: _istFirmenfahrt,
                onChanged: (v) => setState(() => _istFirmenfahrt = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              FilledButton(
                onPressed: _laden ? null : () => _speichern(existing),
                child: _laden
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppDe.speichern),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _speichern(Trip? existing) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _laden = true);

    try {
      final start = DateTime(
        _datum.year, _datum.month, _datum.day,
        _startzeit.hour, _startzeit.minute,
      );
      final end = DateTime(
        _datum.year, _datum.month, _datum.day,
        _endzeit.hour, _endzeit.minute,
      );
      final km = double.parse(
        _distanzController.text.trim().replaceAll(',', '.'),
      );

      final crud = ref.read(tripCrudProvider);

      final kmStart = _kmStartController.text.trim().isNotEmpty
          ? double.tryParse(_kmStartController.text.trim())
          : null;
      final kmEnde = _kmEndeController.text.trim().isNotEmpty
          ? double.tryParse(_kmEndeController.text.trim())
          : null;

      if (existing != null) {
        await crud.aktualisieren(existing.copyWith(
          startTimestamp: start,
          endTimestamp: end,
          distanceKm: km,
          istFirmenfahrt: _istFirmenfahrt,
          kilometerstandStart: kmStart,
          kilometerstandEnde: kmEnde,
          notiz: _notizController.text.trim().isNotEmpty
              ? _notizController.text.trim()
              : null,
          clearNotiz: _notizController.text.trim().isEmpty,
        ));
      } else {
        await crud.manuellErstellen(
          vehicleId: widget.vehicleId,
          startTimestamp: start,
          endTimestamp: end,
          distanceKm: km,
          istFirmenfahrt: _istFirmenfahrt,
          kilometerstandStart: kmStart,
          kilometerstandEnde: kmEnde,
          notiz: _notizController.text.trim().isNotEmpty
              ? _notizController.text.trim()
              : null,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }
}
