import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../data/models/vehicle.dart';

class VehicleListTile extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onAktivieren;
  final VoidCallback onLoeschen;
  final VoidCallback onWartung;

  const VehicleListTile({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onAktivieren,
    required this.onLoeschen,
    required this.onWartung,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: vehicle.fotoPath != null
              ? FileImage(File(vehicle.fotoPath!))
              : null,
          child: vehicle.fotoPath == null
              ? const Icon(Icons.directions_car)
              : null,
        ),
        title: Text(vehicle.name),
        subtitle: Text('${vehicle.kennzeichen} · Bj. ${vehicle.baujahr}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vehicle.aktiv)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Aktiv',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'bearbeiten':
                    onTap();
                  case 'wartung':
                    onWartung();
                  case 'aktivieren':
                    onAktivieren();
                  case 'loeschen':
                    onLoeschen();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'bearbeiten',
                  child: Text('Bearbeiten'),
                ),
                const PopupMenuItem(
                  value: 'wartung',
                  child: Text('Wartung & Service'),
                ),
                if (!vehicle.aktiv)
                  const PopupMenuItem(
                    value: 'aktivieren',
                    child: Text('Als aktiv setzen'),
                  ),
                const PopupMenuItem(
                  value: 'loeschen',
                  child: Text('Löschen', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
