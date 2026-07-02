import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../../../l10n/app_de.dart';
import '../../../../services/trip_detection_service.dart';
import '../../../shared/glass.dart';

class TrackingStatusCard extends StatelessWidget {
  final bool serviceAktiv;
  final TrackingZustand zustand;
  final double aktuelleDistanzKm;
  final VoidCallback onStartenStoppen;
  final VoidCallback onFahrtManuellStarten;
  final VoidCallback onFahrtStoppen;

  const TrackingStatusCard({
    super.key,
    required this.serviceAktiv,
    required this.zustand,
    required this.aktuelleDistanzKm,
    required this.onStartenStoppen,
    required this.onFahrtManuellStarten,
    required this.onFahrtStoppen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusIndikator(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceAktiv
                            ? AppDe.erfassungAktiv
                            : AppDe.erfassungPausiert,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        _statusText(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (zustand == TrackingZustand.tripActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.route,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      aktuelleDistanzKm.kmFormatiert,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStartenStoppen,
                    icon: Icon(serviceAktiv ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      serviceAktiv
                          ? AppDe.erfassungStoppen
                          : AppDe.erfassungStarten,
                    ),
                  ),
                ),
                if (serviceAktiv) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: zustand == TrackingZustand.tripActive
                        ? onFahrtStoppen
                        : onFahrtManuellStarten,
                    child: Text(
                      zustand == TrackingZustand.tripActive
                          ? AppDe.fahrtStoppen
                          : AppDe.fahrtManuellStarten,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndikator() {
    Color farbe;
    bool pulsierend = false;

    switch (zustand) {
      case TrackingZustand.idle:
        farbe = serviceAktiv ? Colors.green : Colors.grey;
      case TrackingZustand.detecting:
        farbe = Colors.orange;
        pulsierend = true;
      case TrackingZustand.tripActive:
        farbe = Colors.green;
        pulsierend = true;
      case TrackingZustand.stopping:
        farbe = Colors.orange;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: farbe,
        shape: BoxShape.circle,
        boxShadow: pulsierend
            ? [BoxShadow(color: farbe.withValues(alpha: 0.5), blurRadius: 8)]
            : null,
      ),
    );
  }

  String _statusText() {
    if (!serviceAktiv) return 'Tippe auf Start um die Erfassung zu beginnen';
    switch (zustand) {
      case TrackingZustand.idle:
        return 'Warte auf Fahrtbeginn…';
      case TrackingZustand.detecting:
        return 'Bewegung erkannt – Fahrt startet automatisch…';
      case TrackingZustand.tripActive:
        return 'Fahrt wird aufgezeichnet';
      case TrackingZustand.stopping:
        return 'Stillstand erkannt – warte auf Fahrtende…';
    }
  }
}
