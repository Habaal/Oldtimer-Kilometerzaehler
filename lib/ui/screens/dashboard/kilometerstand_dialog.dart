import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KilometerstandErgebnis {
  final double kilometerstand;
  final bool istFirmenfahrt;

  const KilometerstandErgebnis({
    required this.kilometerstand,
    required this.istFirmenfahrt,
  });
}

class KilometerstandDialog extends StatefulWidget {
  final double? aktuellerStand;
  final String fahrzeugName;
  final bool istFirmenwagen;

  const KilometerstandDialog({
    super.key,
    this.aktuellerStand,
    required this.fahrzeugName,
    required this.istFirmenwagen,
  });

  static Future<KilometerstandErgebnis?> zeigen(
    BuildContext context, {
    double? aktuellerStand,
    required String fahrzeugName,
    required bool istFirmenwagen,
  }) {
    return Navigator.of(context).push<KilometerstandErgebnis>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => KilometerstandDialog(
          aktuellerStand: aktuellerStand,
          fahrzeugName: fahrzeugName,
          istFirmenwagen: istFirmenwagen,
        ),
      ),
    );
  }

  @override
  State<KilometerstandDialog> createState() => _KilometerstandDialogState();
}

class _KilometerstandDialogState extends State<KilometerstandDialog> {
  final _controller = TextEditingController();
  bool _istFirmenfahrt = false;

  @override
  void initState() {
    super.initState();
    if (widget.aktuellerStand != null) {
      _controller.text = widget.aktuellerStand!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              Icon(
                Icons.speed,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Kilometerstand',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.fahrzeugName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Stimmt der aktuelle Kilometerstand?',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  suffixText: 'km',
                  suffixStyle: theme.textTheme.headlineSmall,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: widget.aktuellerStand == null,
              ),
              if (widget.istFirmenwagen) ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('Privatfahrt'),
                        secondary: const Icon(Icons.person),
                        value: false,
                        groupValue: _istFirmenfahrt,
                        onChanged: (v) => setState(() => _istFirmenfahrt = v!),
                      ),
                      const Divider(height: 1),
                      RadioListTile<bool>(
                        title: const Text('Firmenfahrt'),
                        secondary: const Icon(Icons.business),
                        value: true,
                        groupValue: _istFirmenfahrt,
                        onChanged: (v) => setState(() => _istFirmenfahrt = v!),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(flex: 2),
              FilledButton.icon(
                onPressed: _bestaetigen,
                icon: const Icon(Icons.check),
                label: const Text('Stimmt — Fahrt starten'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bestaetigen() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Kilometerstand eingeben')),
      );
      return;
    }
    final km = double.tryParse(text);
    if (km == null || km < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültiger Kilometerstand')),
      );
      return;
    }
    Navigator.of(context).pop(
      KilometerstandErgebnis(
        kilometerstand: km,
        istFirmenfahrt: _istFirmenfahrt,
      ),
    );
  }
}
