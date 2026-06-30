import 'package:flutter/material.dart';

import '../../l10n/app_de.dart';

Future<bool> bestaetigenDialog(
  BuildContext context, {
  required String titel,
  required String nachricht,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titel),
      content: Text(nachricht),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppDe.abbrechen),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text(AppDe.loeschen),
        ),
      ],
    ),
  );
  return result ?? false;
}
