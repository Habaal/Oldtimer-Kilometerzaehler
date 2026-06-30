import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../../../data/models/trip.dart';

class TripListTile extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onLoeschen;

  const TripListTile({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onLoeschen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dauer = trip.dauer;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: trip.manuellErfasst
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  trip.manuellErfasst ? Icons.edit : Icons.gps_fixed,
                  color: trip.manuellErfasst ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.startTimestamp.datumFormatiert,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${trip.startTimestamp.zeitFormatiert}'
                      '${trip.endTimestamp != null ? ' – ${trip.endTimestamp!.zeitFormatiert}' : ' – läuft…'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (trip.startOrt != null || trip.endOrt != null)
                      Text(
                        [trip.startOrt, trip.endOrt]
                            .where((s) => s != null)
                            .join(' → '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trip.distanceKm.kmFormatiert,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (dauer != null)
                    Text(
                      dauer.dauerFormatiert,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'bearbeiten') onTap();
                  if (value == 'loeschen') onLoeschen();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'bearbeiten',
                    child: Text('Bearbeiten'),
                  ),
                  const PopupMenuItem(
                    value: 'loeschen',
                    child: Text('Löschen', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
