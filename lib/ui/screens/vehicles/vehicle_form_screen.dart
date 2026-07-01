import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../data/models/vehicle.dart';
import '../../../l10n/app_de.dart';
import '../../../providers/vehicle_providers.dart';
import '../../shared/loading_indicator.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const VehicleFormScreen({super.key, this.vehicleId});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _kennzeichenController = TextEditingController();
  final _baujahrController = TextEditingController();
  final _limitController = TextEditingController();
  final _kilometerstandController = TextEditingController();

  String? _fotoPath;
  bool _istFirmenwagen = false;
  bool _laden = false;
  bool _initialisiert = false;

  bool get _istBearbeitung => widget.vehicleId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _kennzeichenController.dispose();
    _baujahrController.dispose();
    _limitController.dispose();
    _kilometerstandController.dispose();
    super.dispose();
  }

  void _fahrzeugLaden(Vehicle vehicle) {
    if (_initialisiert) return;
    _initialisiert = true;
    _nameController.text = vehicle.name;
    _kennzeichenController.text = vehicle.kennzeichen;
    _baujahrController.text = vehicle.baujahr.toString();
    if (vehicle.jahresLimitKm != null) {
      _limitController.text = vehicle.jahresLimitKm!.toStringAsFixed(0);
    }
    if (vehicle.kilometerstand != null) {
      _kilometerstandController.text = vehicle.kilometerstand!.toStringAsFixed(0);
    }
    _fotoPath = vehicle.fotoPath;
    _istFirmenwagen = vehicle.istFirmenwagen;
  }

  @override
  Widget build(BuildContext context) {
    if (_istBearbeitung) {
      final vehicles = ref.watch(vehiclesProvider);
      return vehicles.when(
        loading: () => const Scaffold(body: LoadingIndicator()),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
        data: (liste) {
          final vehicle = liste.where((v) => v.id == widget.vehicleId).firstOrNull;
          if (vehicle == null) {
            return const Scaffold(body: Center(child: Text('Fahrzeug nicht gefunden')));
          }
          _fahrzeugLaden(vehicle);
          return _buildForm(context, vehicle);
        },
      );
    }

    return _buildForm(context, null);
  }

  Widget _buildForm(BuildContext context, Vehicle? existing) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_istBearbeitung ? AppDe.fahrzeugBearbeiten : AppDe.fahrzeugHinzufuegen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _fotoAuswaehlen,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _fotoPath != null ? FileImage(File(_fotoPath!)) : null,
                  child: _fotoPath == null
                      ? const Icon(Icons.camera_alt, size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _fotoAuswaehlen,
                child: Text(_fotoPath == null ? 'Foto hinzufügen' : 'Foto ändern'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppDe.fahrzeugName,
                  hintText: AppDe.fahrzeugNameHint,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? AppDe.pflichtfeld : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kennzeichenController,
                decoration: const InputDecoration(
                  labelText: AppDe.kennzeichen,
                  hintText: AppDe.kennzeichenHint,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v == null || v.trim().isEmpty ? AppDe.pflichtfeld : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baujahrController,
                decoration: const InputDecoration(
                  labelText: AppDe.baujahr,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppDe.pflichtfeld;
                  final jahr = int.tryParse(v);
                  if (jahr == null || jahr < 1886 || jahr > DateTime.now().year) {
                    return 'Ungültiges Baujahr';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(
                  labelText: AppDe.jahresLimit,
                  hintText: AppDe.jahresLimitHint,
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kilometerstandController,
                decoration: const InputDecoration(
                  labelText: 'Aktueller Kilometerstand',
                  hintText: 'z.B. 48350',
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Firmenwagen'),
                subtitle: const Text('Unterscheidet Privat- und Firmenfahrten'),
                value: _istFirmenwagen,
                onChanged: (v) => setState(() => _istFirmenwagen = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _laden ? null : () => _speichern(existing),
                  child: _laden
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppDe.speichern),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fotoAuswaehlen() async {
    final picker = ImagePicker();
    final bild = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (bild == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final dateiName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}${p.extension(bild.path)}';
    final zielPfad = '${appDir.path}/$dateiName';
    await File(bild.path).copy(zielPfad);

    setState(() => _fotoPath = zielPfad);
  }

  Future<void> _speichern(Vehicle? existing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _laden = true);

    try {
      final limit = _limitController.text.trim().isNotEmpty
          ? double.tryParse(_limitController.text.trim())
          : null;
      final km = _kilometerstandController.text.trim().isNotEmpty
          ? double.tryParse(_kilometerstandController.text.trim())
          : null;

      if (existing != null) {
        await ref.read(vehiclesProvider.notifier).aktualisieren(
              existing.copyWith(
                name: _nameController.text.trim(),
                kennzeichen: _kennzeichenController.text.trim(),
                baujahr: int.parse(_baujahrController.text.trim()),
                jahresLimitKm: limit,
                clearJahresLimit: limit == null,
                fotoPath: _fotoPath,
                istFirmenwagen: _istFirmenwagen,
                kilometerstand: km,
                clearKilometerstand: km == null,
              ),
            );
      } else {
        await ref.read(vehiclesProvider.notifier).erstellen(
              name: _nameController.text.trim(),
              kennzeichen: _kennzeichenController.text.trim(),
              baujahr: int.parse(_baujahrController.text.trim()),
              jahresLimitKm: limit,
              fotoPath: _fotoPath,
              istFirmenwagen: _istFirmenwagen,
              kilometerstand: km,
            );
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }
}
