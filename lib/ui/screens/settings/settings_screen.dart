import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/repositories/location_point_repository.dart';
import '../../../l10n/app_de.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/tracking_providers.dart';
import '../../../services/location_service.dart';
import '../../shared/confirmation_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _locationService = LocationService();
  bool? _hintergrundBerechtigung;

  @override
  void initState() {
    super.initState();
    _berechtigungPruefen();
  }

  Future<void> _berechtigungPruefen() async {
    final erteilt = await _locationService.hintergrundBerechtigungPruefen();
    if (mounted) setState(() => _hintergrundBerechtigung = erteilt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paused = ref.watch(trackingPausiertProvider);
    final serviceAktiv = ref.watch(serviceAktivProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppDe.einstellungen)),
      body: ListView(
        children: [
          // Standort-Berechtigung
          _sektionsHeader(theme, AppDe.standortBerechtigung),
          ListTile(
            leading: Icon(
              _hintergrundBerechtigung == true
                  ? Icons.check_circle
                  : Icons.warning,
              color: _hintergrundBerechtigung == true
                  ? Colors.green
                  : Colors.orange,
            ),
            title: Text(
              _hintergrundBerechtigung == true
                  ? AppDe.berechtigungErteilt
                  : AppDe.berechtigungFehlt,
            ),
            subtitle: _hintergrundBerechtigung != true
                ? const Text(
                    'Für automatische Erfassung wird "Immer erlauben" benötigt.')
                : null,
            trailing: _hintergrundBerechtigung != true
                ? TextButton(
                    onPressed: () async {
                      await _locationService.hintergrundBerechtigungAnfordern();
                      _berechtigungPruefen();
                    },
                    child: const Text(AppDe.berechtigungAnfordern),
                  )
                : null,
          ),

          // Tracking
          _sektionsHeader(theme, 'Erfassung'),
          SwitchListTile(
            title: const Text('Erfassung pausieren'),
            subtitle: const Text(
                'Wenn aktiviert, werden keine Fahrten automatisch erkannt.'),
            value: paused,
            onChanged: (value) {
              ref.read(trackingPausiertProvider.notifier).state = value;
              if (value && serviceAktiv) {
                ref.read(trackingControllerProvider).stoppen();
              }
            },
          ),

          // Datenverwaltung
          _sektionsHeader(theme, AppDe.datenverwaltung),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text(AppDe.gpsPunkteLoeschen),
            subtitle: const Text(
                'Spart Speicherplatz. Achtung: Die Strecken können danach '
                'nicht mehr auf der Karte angezeigt werden.'),
            onTap: () async {
              final bestaetigt = await bestaetigenDialog(
                context,
                titel: AppDe.gpsPunkteLoeschen,
                nachricht:
                    'Alle GPS-Punkte abgeschlossener Fahrten löschen? '
                    'Die Karten-Ansicht dieser Fahrten geht dabei '
                    'unwiderruflich verloren. Die Kilometer bleiben '
                    'erhalten.',
              );
              if (!bestaetigt) return;
              final repo = LocationPointRepository();
              final anzahl = await repo.abgeschlosseneLoeschen();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$anzahl GPS-Punkte gelöscht.')),
                );
              }
            },
          ),

          // Info
          _sektionsHeader(theme, AppDe.info),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('${AppDe.appName} · ${AppDe.version} 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text(AppDe.datenschutz),
            subtitle: Text(AppDe.datenschutzText),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/via-lab-logo.svg',
                  height: 40,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppDe.firmenName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppDe.appName} – entwickelt von ${AppDe.firmenName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© ${DateTime.now().year} ${AppDe.firmenName}. '
                  'Alle Rechte vorbehalten.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sektionsHeader(ThemeData theme, String titel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        titel,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
