#!/bin/bash
# ============================================================
# Oldtimer KM-Log — Build-Skript für iOS
# Baut die App und öffnet Xcode zum Installieren auf dem iPhone.
# Ausführen: chmod +x build.sh && ./build.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "=========================================="
echo "  Oldtimer KM-Log — Build"
echo "=========================================="
echo ""

# ----------------------------------------------------------
# Voraussetzungen prüfen
# ----------------------------------------------------------
if ! command -v flutter &>/dev/null; then
    echo -e "${RED}✗ Flutter ist nicht installiert!${NC}"
    echo "  Führe zuerst ./setup.sh aus."
    exit 1
fi

if [ ! -d "ios" ]; then
    echo -e "${RED}✗ iOS-Ordner fehlt!${NC}"
    echo "  Führe zuerst ./setup.sh aus."
    exit 1
fi

if [ ! -f "ios/Podfile.lock" ]; then
    echo -e "${YELLOW}→ CocoaPods werden installiert…${NC}"
    cd ios && pod install && cd ..
fi

# ----------------------------------------------------------
# 1. Pakete aktualisieren
# ----------------------------------------------------------
echo -e "${YELLOW}→ Pakete werden aktualisiert…${NC}"
flutter pub get
echo -e "${GREEN}✓ Pakete aktuell${NC}"

# ----------------------------------------------------------
# 2. Code analysieren
# ----------------------------------------------------------
echo -e "${YELLOW}→ Code wird analysiert…${NC}"
flutter analyze --no-fatal-infos 2>&1 | tail -5 || true
echo ""

# ----------------------------------------------------------
# 3. iOS-App bauen
# ----------------------------------------------------------
echo -e "${YELLOW}→ iOS-App wird gebaut (Debug)…${NC}"
echo "  Das kann beim ersten Mal einige Minuten dauern."
echo ""
flutter build ios --debug --no-codesign 2>&1 | tail -10
echo ""
echo -e "${GREEN}✓ Build erfolgreich!${NC}"

# ----------------------------------------------------------
# 4. Xcode öffnen
# ----------------------------------------------------------
echo ""
echo "=========================================="
echo -e "${GREEN}  Build abgeschlossen!${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}Xcode wird geöffnet…${NC}"
echo ""
echo "In Xcode:"
echo "  1. Wähle links 'Runner' im Navigator"
echo "  2. Unter 'Signing & Capabilities':"
echo "     - 'Automatically manage signing' aktivieren"
echo "     - Team: deinen Apple-Account wählen ('Personal Team')"
echo "     - Bundle Identifier auf etwas Einzigartiges ändern"
echo "       (z.B. com.deinname.oldtimerkmlog)"
echo ""
echo "  3. Unter 'Signing & Capabilities' → '+ Capability':"
echo "     - 'Background Modes' hinzufügen"
echo "     - 'Location updates' aktivieren"
echo ""
echo "  4. iPhone per USB anschließen"
echo "  5. Oben dein iPhone als Zielgerät auswählen"
echo "  6. Auf Run (▶) klicken"
echo ""
echo "  7. Auf dem iPhone:"
echo "     - Einstellungen → Allgemein → VPN & Geräteverwaltung"
echo "     - Dem Entwicklerzertifikat vertrauen"
echo "     - App öffnen"
echo ""

open ios/Runner.xcworkspace
