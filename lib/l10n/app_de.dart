class AppDe {
  AppDe._();

  // App
  static const String appName = 'Drivio';
  static const String firmenName = 'Via Lab';

  // Navigation
  static const String dashboard = 'Dashboard';
  static const String fahrzeuge = 'Fahrzeuge';
  static const String fahrten = 'Fahrten';
  static const String statistik = 'Statistik';
  static const String export = 'Export';
  static const String einstellungen = 'Einstellungen';

  // Fahrzeuge
  static const String fahrzeugHinzufuegen = 'Fahrzeug hinzufügen';
  static const String fahrzeugBearbeiten = 'Fahrzeug bearbeiten';
  static const String fahrzeugName = 'Name';
  static const String fahrzeugNameHint = 'z.B. Mercedes W123';
  static const String kennzeichen = 'Kennzeichen';
  static const String kennzeichenHint = 'z.B. BR-OT 123';
  static const String baujahr = 'Baujahr';
  static const String jahresLimit = 'Jahres-KM-Limit (optional)';
  static const String jahresLimitHint = 'z.B. 5000';
  static const String speichern = 'Speichern';
  static const String abbrechen = 'Abbrechen';
  static const String loeschen = 'Löschen';
  static const String bearbeiten = 'Bearbeiten';
  static const String aktivieren = 'Als aktiv setzen';
  static const String keinFahrzeug = 'Noch kein Fahrzeug angelegt';
  static const String keinFahrzeugInfo =
      'Tippe auf + um dein erstes Fahrzeug hinzuzufügen.';
  static const String fahrzeugLoeschenBestaetigung =
      'Möchtest du dieses Fahrzeug wirklich löschen? Alle zugehörigen Fahrten werden ebenfalls gelöscht.';

  // Dashboard
  static const String keinAktivesFahrzeug = 'Kein Fahrzeug ausgewählt';
  static const String fahrzeugWaehlen = 'Fahrzeug wählen';
  static const String erfassungAktiv = 'Erfassung aktiv';
  static const String erfassungPausiert = 'Erfassung pausiert';
  static const String erfassungStarten = 'Erfassung starten';
  static const String erfassungStoppen = 'Erfassung stoppen';
  static const String fahrtManuellStarten = 'Fahrt manuell starten';
  static const String fahrtStoppen = 'Fahrt stoppen';
  static const String jahresKm = 'Jahreskilometer';
  static const String keinLimit = 'Kein Limit gesetzt';

  // Fahrten
  static const String fahrtHinzufuegen = 'Fahrt nachtragen';
  static const String fahrtBearbeiten = 'Fahrt bearbeiten';
  static const String datum = 'Datum';
  static const String startzeit = 'Startzeit';
  static const String endzeit = 'Endzeit';
  static const String distanz = 'Distanz (km)';
  static const String notiz = 'Notiz (optional)';
  static const String keinefahrten = 'Noch keine Fahrten erfasst';
  static const String keinefahrtenInfo =
      'Starte die Erfassung oder trage eine Fahrt manuell nach.';
  static const String alleFahrzeuge = 'Alle Fahrzeuge';
  static const String zeitraumFilter = 'Zeitraum filtern';
  static const String fahrtLoeschenBestaetigung =
      'Möchtest du diese Fahrt wirklich löschen?';
  static const String manuell = 'Manuell';
  static const String gps = 'GPS';
  static const String von = 'Von';
  static const String bis = 'Bis';

  // Statistik
  static const String diesesJahr = 'Dieses Jahr';
  static const String letztesJahr = 'Letztes Jahr';
  static const String gesamt = 'Gesamt';
  static const String monatsUebersicht = 'Monatsübersicht';

  // Export
  static const String exportTitel = 'Fahrtenbuch exportieren';
  static const String formatWaehlen = 'Format wählen';
  static const String zeitraumWaehlen = 'Zeitraum wählen';
  static const String exportieren = 'Exportieren & Teilen';
  static const String csvFormat = 'CSV (für Excel)';
  static const String pdfFormat = 'PDF (für Versicherung)';
  static const String exportErfolgreich = 'Export erstellt und geteilt!';

  // Einstellungen
  static const String standortBerechtigung = 'Standort-Berechtigung';
  static const String berechtigungErteilt = 'Erteilt (Immer)';
  static const String berechtigungFehlt = 'Nicht erteilt';
  static const String berechtigungAnfordern = 'Berechtigung anfordern';
  static const String datenverwaltung = 'Datenverwaltung';
  static const String gpsPunkteLoeschen = 'GPS-Punkte bereinigen';
  static const String alleDatenLoeschen = 'Alle Daten löschen';
  static const String info = 'Info';
  static const String version = 'Version';
  static const String datenschutz = 'Datenschutz';
  static const String datenschutzText =
      'Alle Daten werden ausschließlich lokal auf diesem Gerät gespeichert. '
      'Es werden keine Daten an Server oder Dritte übermittelt.';

  // Berechtigungs-Onboarding
  static const String berechtigungTitel = 'Standort-Zugriff benötigt';
  static const String berechtigungErklaerung =
      'Um gefahrene Kilometer automatisch zu erfassen, benötigt die App '
      'dauerhaften Zugriff auf deinen Standort – auch im Hintergrund.\n\n'
      'Bitte wähle im nächsten Dialog "Immer erlauben".\n\n'
      'Deine Standortdaten verlassen niemals dieses Gerät.';
  static const String verstanden = 'Verstanden';

  // Allgemein
  static const String ja = 'Ja';
  static const String nein = 'Nein';
  static const String ok = 'OK';
  static const String fehler = 'Fehler';
  static const String pflichtfeld = 'Dieses Feld ist erforderlich';
}
