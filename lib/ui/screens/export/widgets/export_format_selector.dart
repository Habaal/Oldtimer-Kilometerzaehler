import 'package:flutter/material.dart';

import '../../../../l10n/app_de.dart';

enum ExportFormat { csv, pdf }

class ExportFormatSelector extends StatelessWidget {
  final ExportFormat selected;
  final ValueChanged<ExportFormat> onChanged;

  const ExportFormatSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppDe.formatWaehlen,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ExportFormat>(
          segments: const [
            ButtonSegment(
              value: ExportFormat.csv,
              icon: Icon(Icons.table_chart),
              label: Text(AppDe.csvFormat),
            ),
            ButtonSegment(
              value: ExportFormat.pdf,
              icon: Icon(Icons.picture_as_pdf),
              label: Text(AppDe.pdfFormat),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (set) => onChanged(set.first),
        ),
      ],
    );
  }
}
