#!/bin/bash
# ============================================================
# Oldtimer KM-Log — App im iOS-Simulator starten
# Ausführen: chmod +x simulator.sh && ./simulator.sh
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

if ! command -v flutter &>/dev/null; then
    FLUTTER_PATH="$(find /opt/homebrew/Caskroom/flutter /usr/local/Caskroom/flutter -name flutter -type f 2>/dev/null | grep '/bin/flutter$' | head -1)"
    if [[ -n "$FLUTTER_PATH" ]]; then
        export PATH="$PATH:$(dirname "$FLUTTER_PATH")"
    fi
fi

if ! command -v flutter &>/dev/null; then
    source ~/.zprofile 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo "  Oldtimer KM-Log — Simulator"
echo "=========================================="
echo ""

if ! command -v flutter &>/dev/null; then
    echo -e "${RED}✗ Flutter nicht gefunden! Führe zuerst ./setup.sh aus.${NC}"
    exit 1
fi

# ----------------------------------------------------------
# iOS-Ordner prüfen
# ----------------------------------------------------------
if [ ! -d "ios" ]; then
    echo -e "${YELLOW}→ Flutter-Projekt wird initialisiert…${NC}"
    flutter create --org com.oldtimer .
    flutter pub get
    cd ios && pod install && cd ..
fi

# ----------------------------------------------------------
# Simulator starten
# ----------------------------------------------------------
echo -e "${YELLOW}→ iOS-Simulator wird gestartet…${NC}"
open -a Simulator 2>/dev/null || true
sleep 3

# Verfügbare Simulatoren anzeigen
echo ""
echo -e "${CYAN}Verfügbare iPhone-Simulatoren:${NC}"
xcrun simctl list devices available | grep -i "iphone" | head -10
echo ""

# Einen iPhone-Simulator booten (neuestes iPhone nehmen)
SIMULATOR_ID=$(xcrun simctl list devices available | grep -i "iphone" | grep -v "unavailable" | tail -1 | grep -oE '[A-F0-9-]{36}')

if [[ -z "$SIMULATOR_ID" ]]; then
    echo -e "${RED}✗ Kein iPhone-Simulator gefunden!${NC}"
    echo "  Öffne Xcode → Settings → Platforms → lade einen iOS-Simulator herunter."
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices available | grep "$SIMULATOR_ID" | sed 's/ (.*//' | xargs)
echo -e "${GREEN}→ Verwende: $SIMULATOR_NAME${NC}"

xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true

# ----------------------------------------------------------
# App im Simulator starten
# ----------------------------------------------------------
echo ""
echo -e "${YELLOW}→ App wird im Simulator gestartet…${NC}"
echo "  Das kann beim ersten Mal 2-3 Minuten dauern."
echo "  Die App öffnet sich automatisch im Simulator."
echo ""
echo -e "${CYAN}  Zum Beenden: Ctrl+C drücken${NC}"
echo ""

flutter run --device-id "$SIMULATOR_ID"
