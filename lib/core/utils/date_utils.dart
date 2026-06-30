class AppDateUtils {
  AppDateUtils._();

  static final List<String> monatsNamen = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  static final List<String> monatsNamenLang = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  /// Anfang des aktuellen Jahres
  static DateTime jahresAnfang([int? jahr]) {
    final j = jahr ?? DateTime.now().year;
    return DateTime(j, 1, 1);
  }

  /// Ende des aktuellen Jahres
  static DateTime jahresEnde([int? jahr]) {
    final j = jahr ?? DateTime.now().year;
    return DateTime(j, 12, 31, 23, 59, 59);
  }

  /// Anfang eines Monats
  static DateTime monatsAnfang(int jahr, int monat) {
    return DateTime(jahr, monat, 1);
  }

  /// Ende eines Monats
  static DateTime monatsEnde(int jahr, int monat) {
    return DateTime(jahr, monat + 1, 0, 23, 59, 59);
  }
}
