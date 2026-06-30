import 'package:intl/intl.dart';

extension DateTimeFormatting on DateTime {
  String get datumFormatiert => DateFormat('dd.MM.yyyy').format(this);

  String get zeitFormatiert => DateFormat('HH:mm').format(this);

  String get datumZeitFormatiert => DateFormat('dd.MM.yyyy HH:mm').format(this);

  String get monatJahrFormatiert => DateFormat('MMMM yyyy', 'de_DE').format(this);

  String get isoString => toIso8601String();
}

extension DoubleFormatting on double {
  String get kmFormatiert {
    final formatter = NumberFormat('#,##0.0', 'de_DE');
    return '${formatter.format(this)} km';
  }

  String get kmKurzFormatiert {
    if (this >= 1000) {
      final formatter = NumberFormat('#,##0', 'de_DE');
      return '${formatter.format(this)} km';
    }
    final formatter = NumberFormat('#,##0.0', 'de_DE');
    return '${formatter.format(this)} km';
  }
}

extension DurationFormatting on Duration {
  String get dauerFormatiert {
    final stunden = inHours;
    final minuten = inMinutes.remainder(60);
    if (stunden > 0) {
      return '${stunden}h ${minuten}min';
    }
    return '${minuten} min';
  }
}
