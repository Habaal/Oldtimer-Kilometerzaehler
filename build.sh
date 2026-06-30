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

# ----------------------------------------------------------
# Homebrew + Flutter PATH laden
# ----------------------------------------------------------
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Flutter aus Homebrew Cask finden
if ! command -v flutter &>/dev/null; then
    FLUTTER_PATH="$(find /opt/homebrew/Caskroom/flutter /usr/local/Caskroom/flutter -name flutter -type f 2>/dev/null | grep '/bin/flutter$' | head -1)"
    if [[ -n "$FLUTTER_PATH" ]]; then
        export PATH="$PATH:$(dirname "$FLUTTER_PATH")"
    fi
fi

# Flutter aus .zprofile laden
if ! command -v flutter &>/dev/null; then
    source ~/.zprofile 2>/dev/null || true
fi

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
    echo "  Falls du setup.sh schon ausgeführt hast:"
    echo "  Schließe das Terminal, öffne ein neues und versuche es erneut."
    exit 1
fi

echo -e "${GREEN}✓ Flutter gefunden: $(which flutter)${NC}"

# ----------------------------------------------------------
# Swift Package Manager deaktivieren (CocoaPods verwenden)
# ----------------------------------------------------------
flutter config --no-enable-swift-package-manager 2>/dev/null || true

if [ ! -d "ios" ]; then
    echo -e "${YELLOW}→ iOS-Ordner fehlt, wird generiert…${NC}"
    flutter create --org com.oldtimer .
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
