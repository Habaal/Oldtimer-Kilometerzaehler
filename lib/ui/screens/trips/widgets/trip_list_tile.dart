import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../../../data/models/trip.dart';

class TripListTile extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onBearbeiten;
  final VoidCallback onLoeschen;

  const TripListTile({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onBearbeiten,
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
                  color: trip.istFirmenfahrt
                      ? Colors.orange.shade50
                      : trip.manuellErfasst
                          ? Colors.blue.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  trip.istFirmenfahrt
                      ? Icons.business
                      : trip.manuellErfasst
                          ? Icons.edit
                          : Icons.gps_fixed,
                  color: trip.istFirmenfahrt
                      ? Colors.orange
                      : trip.manuellErfasst
                          ? Colors.blue
                          : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          trip.startTimestamp.datumFormatiert,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(width: 8),
                        _fahrtTypChip(theme),
                      ],
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  if (value == 'karte') onTap();
                  if (value == 'bearbeiten') onBearbeiten();
                  if (value == 'loeschen') onLoeschen();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'karte',
                    child: ListTile(
                      leading: Icon(Icons.map),
                      title: Text('Karte anzeigen'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bearbeiten',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Bearbeiten'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'loeschen',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Löschen',
                          style: TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fahrtTypChip(ThemeData theme) {
    if (trip.istFirmenfahrt) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Firma',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.orange.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Privat',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.green.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
