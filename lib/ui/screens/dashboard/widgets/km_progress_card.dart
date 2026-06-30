import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../../../l10n/app_de.dart';

class KmProgressCard extends StatelessWidget {
  final double aktuelleKm;
  final double? limitKm;

  const KmProgressCard({
    super.key,
    required this.aktuelleKm,
    this.limitKm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fortschritt = limitKm != null && limitKm! > 0
        ? (aktuelleKm / limitKm!).clamp(0.0, 1.0)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppDe.jahresKm,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  aktuelleKm.kmKurzFormatiert,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (limitKm != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '/ ${limitKm!.kmKurzFormatiert}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (fortschritt != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fortschritt,
                  minHeight: 12,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  color: fortschritt > 0.9
                      ? Colors.red
                      : fortschritt > 0.7
                          ? Colors.orange
                          : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(fortschritt * 100).toStringAsFixed(0)}% des Jahreslimits',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (limitKm == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppDe.keinLimit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
