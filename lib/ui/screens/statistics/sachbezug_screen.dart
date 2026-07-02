import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/vehicle.dart';
import '../../../providers/statistics_providers.dart';

/// Sachbezug-Sätze laut österreichischem Recht.
enum SachbezugSatz {
  standard(0.02, 960.0, '2 % (Standard)'),
  co2Arm(0.015, 720.0, '1,5 % (CO₂-arm)'),
  elektro(0.0, 0.0, '0 % (Elektro)');

  final double satz;
  final double maxProMonat;
  final String label;
  const SachbezugSatz(this.satz, this.maxProMonat, this.label);
}

class SachbezugScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const SachbezugScreen({super.key, required this.vehicle});

  @override
  ConsumerState<SachbezugScreen> createState() => _SachbezugScreenState();
}

class _SachbezugScreenState extends ConsumerState<SachbezugScreen> {
  final _kostenController = TextEditingController();
  SachbezugSatz _satz = SachbezugSatz.standard;

  static const double _halberSachbezugGrenzeKmProJahr = 6000.0;

  @override
  void dispose() {
    _kostenController.dispose();
    super.dispose();
  }

  String _euro(double betrag) {
    final formatter = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    return formatter.format(betrag);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jahr = DateTime.now().year;
    final privateKm = ref.watch(privateJahresKmProvider(
      JahresKmParams(vehicleId: widget.vehicle.id, jahr: jahr),
    ));

    final anschaffungskosten =
        double.tryParse(_kostenController.text.replaceAll(',', '.'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sachbezugrechner'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business_center,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.vehicle.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Berechnung des monatlichen Sachbezugs für die '
                    'Privatnutzung des Firmenwagens (Österreich).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Eingaben
          TextField(
            controller: _kostenController,
            decoration: const InputDecoration(
              labelText: 'Anschaffungskosten (inkl. USt und NoVA)',
              suffixText: '€',
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (final satz in SachbezugSatz.values) ...[
                  RadioListTile<SachbezugSatz>(
                    title: Text(satz.label),
                    subtitle: satz == SachbezugSatz.co2Arm
                        ? const Text(
                            'CO₂-Emission unter dem Grenzwert im '
                            'Anschaffungsjahr')
                        : satz == SachbezugSatz.elektro
                            ? const Text('0 g CO₂/km — kein Sachbezug')
                            : null,
                    value: satz,
                    groupValue: _satz,
                    onChanged: (v) => setState(() => _satz = v!),
                  ),
                  if (satz != SachbezugSatz.values.last)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Private Kilometer aus der App
          privateKm.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Fehler: $e'),
            data: (km) => _ergebnis(theme, km, jahr, anschaffungskosten),
          ),

          const SizedBox(height: 16),
          Text(
            'Alle Angaben ohne Gewähr. Maßgeblich ist die '
            'Sachbezugswerteverordnung in der jeweils geltenden Fassung.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _ergebnis(
    ThemeData theme,
    double privateKmBisJetzt,
    int jahr,
    double? anschaffungskosten,
  ) {
    // Private km aufs Jahr hochrechnen
    final jetzt = DateTime.now();
    final tagImJahr = jetzt.difference(DateTime(jahr, 1, 1)).inDays + 1;
    final hochgerechnetKm = jahr == jetzt.year && tagImJahr < 365
        ? privateKmBisJetzt / tagImJahr * 365
        : privateKmBisJetzt;

    final halberSachbezug =
        hochgerechnetKm <= _halberSachbezugGrenzeKmProJahr;

    double? monatlich;
    if (anschaffungskosten != null && anschaffungskosten > 0) {
      monatlich = anschaffungskosten * _satz.satz;
      if (monatlich > _satz.maxProMonat) monatlich = _satz.maxProMonat;
      if (halberSachbezug) monatlich = monatlich / 2;
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ergebnis',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            _zeile(
              theme,
              'Private km $jahr (erfasst)',
              '${privateKmBisJetzt.toStringAsFixed(0)} km',
            ),
            _zeile(
              theme,
              'Hochgerechnet aufs Jahr',
              '${hochgerechnetKm.toStringAsFixed(0)} km',
            ),
            _zeile(
              theme,
              'Halber Sachbezug (≤ 6.000 km/Jahr)',
              halberSachbezug ? 'Ja ✓' : 'Nein',
            ),
            const Divider(),
            if (monatlich != null) ...[
              _zeile(
                theme,
                'Sachbezug pro Monat',
                _euro(monatlich),
                fett: true,
              ),
              _zeile(
                theme,
                'Sachbezug pro Jahr',
                _euro(monatlich * 12),
                fett: true,
              ),
            ] else
              Text(
                'Anschaffungskosten eingeben, um den Sachbezug zu berechnen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _zeile(ThemeData theme, String label, String wert,
      {bool fett = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Text(
            wert,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: fett ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
