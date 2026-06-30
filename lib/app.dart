import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'l10n/app_de.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'ui/shared/app_scaffold.dart';

class OldtimerKmLogApp extends StatelessWidget {
  const OldtimerKmLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppDe.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('de', 'DE'),
      home: const AppScaffold(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
