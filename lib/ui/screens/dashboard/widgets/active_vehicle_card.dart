import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../data/models/vehicle.dart';
import '../../../../l10n/app_de.dart';
import '../../../shared/glass.dart';

class ActiveVehicleCard extends StatelessWidget {
  final Vehicle? vehicle;
  final VoidCallback onWechseln;

  const ActiveVehicleCard({
    super.key,
    required this.vehicle,
    required this.onWechseln,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return GlassCard(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.directions_car),
          ),
          title: const Text(AppDe.keinAktivesFahrzeug),
          trailing: FilledButton(
            onPressed: onWechseln,
            child: const Text(AppDe.fahrzeugWaehlen),
          ),
        ),
      );
    }

    return GlassCard(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: vehicle!.fotoPath != null
              ? FileImage(File(vehicle!.fotoPath!))
              : null,
          child: vehicle!.fotoPath == null
              ? const Icon(Icons.directions_car)
              : null,
        ),
        title: Text(vehicle!.name),
        subtitle: Text('${vehicle!.kennzeichen} · Bj. ${vehicle!.baujahr}'),
        trailing: TextButton.icon(
          onPressed: onWechseln,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Wechseln'),
        ),
      ),
    );
  }
}
