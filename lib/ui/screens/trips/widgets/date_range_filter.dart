import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../../../l10n/app_de.dart';

class DateRangeFilter extends StatelessWidget {
  final DateTime? von;
  final DateTime? bis;
  final ValueChanged<DateTimeRange?> onChanged;

  const DateRangeFilter({
    super.key,
    this.von,
    this.bis,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hatFilter = von != null || bis != null;

    return Wrap(
      spacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.date_range, size: 18),
          label: Text(
            von != null
                ? '${AppDe.von}: ${von!.datumFormatiert}'
                : AppDe.von,
          ),
          onPressed: () => _datumWaehlen(context, istVon: true),
        ),
        ActionChip(
          avatar: const Icon(Icons.date_range, size: 18),
          label: Text(
            bis != null
                ? '${AppDe.bis}: ${bis!.datumFormatiert}'
                : AppDe.bis,
          ),
          onPressed: () => _datumWaehlen(context, istVon: false),
        ),
        if (hatFilter)
          ActionChip(
            avatar: const Icon(Icons.clear, size: 18),
            label: const Text('Filter löschen'),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  Future<void> _datumWaehlen(BuildContext context,
      {required bool istVon}) async {
    final datum = await showDatePicker(
      context: context,
      initialDate: (istVon ? von : bis) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('de', 'DE'),
    );
    if (datum == null) return;

    final neuesVon = istVon ? datum : (von ?? DateTime(2000));
    final neuesBis = istVon ? (bis ?? DateTime.now()) : datum;

    onChanged(DateTimeRange(start: neuesVon, end: neuesBis));
  }
}
