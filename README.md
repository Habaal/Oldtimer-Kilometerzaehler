# Oldtimer KM-Log

Automatische Kilometererfassung per GPS für Oldtimer-Fahrzeuge.
Die App erfasst im Hintergrund gefahrene Kilometer und erstellt Berichte für die Kfz-Versicherung.

## Features

- Mehrere Oldtimer als Profile verwalten
- Automatische Fahrterkennung per GPS im Hintergrund
- Manuelle Fahrten nachtragen
- Jahreskilometer-Übersicht mit Fortschrittsanzeige gegen Versicherungslimit
- Export als CSV und PDF für die Versicherung
- Alle Daten bleiben lokal auf dem Gerät

## Voraussetzungen

- Mac mit [Flutter SDK](https://docs.flutter.dev/get-started/install/macos) (>= 3.8.0)
- Xcode (aus dem App Store)
- iPhone mit USB-Kabel
- Kostenloser Apple-Account (Apple-ID)

## Build & Installation

```bash
# 1. Repository klonen
git clone <repo-url>
cd Oldtimer-Kilometerzaehler

# 2. Flutter-Projekt generieren (erstellt ios/ Ordner)
flutter create --org com.oldtimer .

# 3. Abhängigkeiten installieren
flutter pub get

# 4. iOS-Pods installieren
cd ios && pod install && cd ..

# 5. In Xcode öffnen
open ios/Runner.xcworkspace
```

### In Xcode

1. Links im Navigator "Runner" auswählen
2. Unter **Signing & Capabilities**:
   - "Automatically manage signing" aktivieren
   - Team: eigenen Apple-Account auswählen ("Personal Team")
   - Bundle Identifier auf etwas Einzigartiges ändern (z.B. `com.deinname.oldtimerkmlog`)
3. Unter **Signing & Capabilities** → **+ Capability**:
   - "Background Modes" hinzufügen
   - "Location updates" aktivieren
4. iPhone per USB anschließen und als Zielgerät auswählen
5. Auf **Run** (▶) klicken

### Auf dem iPhone

1. Einstellungen → Allgemein → VPN & Geräteverwaltung
2. Dem Entwicklerzertifikat vertrauen
3. App öffnen und Standortberechtigung "Immer erlauben" wählen

> **Hinweis:** Mit einem kostenlosen Apple-Account läuft die App 7 Tage, danach muss sie in Xcode erneut installiert werden.

## Datenschutz

- Alle Daten werden ausschließlich lokal auf dem Gerät gespeichert (SQLite)
- Keine Cloud-Anbindung, keine Analytics, kein Tracking
- Standortdaten verlassen niemals das Gerät
- GPS-Punkte werden nach Trip-Ende verworfen, nur die Distanzsumme wird gespeichert
