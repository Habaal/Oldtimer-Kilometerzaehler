import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../../../l10n/app_de.dart';

class YearComparisonCard extends StatelessWidget {
  final double diesesJahrKm;
  final double letztesJahrKm;
  final double gesamtKm;

  const YearComparisonCard({
    super.key,
    required this.diesesJahrKm,
    required this.letztesJahrKm,
    required this.gesamtKm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _kennzahl(theme, AppDe.diesesJahr, diesesJahrKm),
            _trennlinie(theme),
            _kennzahl(theme, AppDe.letztesJahr, letztesJahrKm),
            _trennlinie(theme),
            _kennzahl(theme, AppDe.gesamt, gesamtKm),
          ],
        ),
      ),
    );
  }

  Widget _kennzahl(ThemeData theme, String label, double km) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            km.kmKurzFormatiert,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trennlinie(ThemeData theme) {
    return Container(
      width: 1,
      height: 40,
      color: theme.dividerColor,
    );
  }
}
