#!/bin/bash
# ============================================================
# Oldtimer KM-Log — Setup-Skript für macOS
# Installiert alle benötigten Tools und Abhängigkeiten.
# Ausführen: chmod +x setup.sh && ./setup.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=========================================="
echo "  Oldtimer KM-Log — Setup"
echo "=========================================="
echo ""

# ----------------------------------------------------------
# 1. Homebrew prüfen / installieren
# ----------------------------------------------------------
if command -v brew &>/dev/null; then
    echo -e "${GREEN}✓ Homebrew ist installiert${NC}"
else
    echo -e "${YELLOW}→ Homebrew wird installiert…${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Homebrew zum PATH hinzufügen (Apple Silicon)
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
    echo -e "${GREEN}✓ Homebrew installiert${NC}"
fi

# ----------------------------------------------------------
# 2. Xcode Command Line Tools prüfen
# ----------------------------------------------------------
if xcode-select -p &>/dev/null; then
    echo -e "${GREEN}✓ Xcode Command Line Tools sind installiert${NC}"
else
    echo -e "${YELLOW}→ Xcode Command Line Tools werden installiert…${NC}"
    xcode-select --install
    echo -e "${YELLOW}  Bitte warte bis die Installation abgeschlossen ist und starte das Skript erneut.${NC}"
    exit 1
fi

# ----------------------------------------------------------
# 3. Xcode prüfen
# ----------------------------------------------------------
if [ -d "/Applications/Xcode.app" ]; then
    echo -e "${GREEN}✓ Xcode ist installiert${NC}"
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>/dev/null || true
    sudo xcodebuild -license accept 2>/dev/null || true
else
    echo -e "${RED}✗ Xcode ist nicht installiert!${NC}"
    echo "  Bitte installiere Xcode aus dem App Store:"
    echo "  https://apps.apple.com/app/xcode/id497799835"
    echo ""
    echo "  Nach der Installation starte dieses Skript erneut."
    exit 1
fi

# ----------------------------------------------------------
# 4. CocoaPods prüfen / installieren
# ----------------------------------------------------------
if command -v pod &>/dev/null; then
    echo -e "${GREEN}✓ CocoaPods ist installiert$(pod --version 2>/dev/null | head -1 | sed 's/^/ (v/')$(pod --version 2>/dev/null | head -1 | sed 's/.*/)/' | head -c 0 && pod --version 2>/dev/null | head -1 | awk '{print " (v"$1")"}'  2>/dev/null || echo '')${NC}"
else
    echo -e "${YELLOW}→ CocoaPods wird installiert…${NC}"
    brew install cocoapods
    echo -e "${GREEN}✓ CocoaPods installiert${NC}"
fi

# ----------------------------------------------------------
# 5. Flutter SDK prüfen / installieren
# ----------------------------------------------------------
if command -v flutter &>/dev/null; then
    echo -e "${GREEN}✓ Flutter ist installiert$(flutter --version 2>/dev/null | head -1 | awk '{print " (v"$2")"}'  || echo '')${NC}"
else
    echo -e "${YELLOW}→ Flutter wird installiert…${NC}"
    brew install --cask flutter

    # Flutter zum PATH hinzufügen
    export PATH="$PATH:$(brew --prefix)/Caskroom/flutter/*/flutter/bin"

    echo -e "${GREEN}✓ Flutter installiert${NC}"
    echo -e "${YELLOW}  Hinweis: Starte ein neues Terminal oder führe 'source ~/.zprofile' aus,${NC}"
    echo -e "${YELLOW}  damit 'flutter' im PATH verfügbar ist.${NC}"
fi

# ----------------------------------------------------------
# 6. Flutter Doctor
# ----------------------------------------------------------
echo ""
echo -e "${YELLOW}→ Prüfe Flutter-Umgebung…${NC}"
flutter doctor --android-licenses 2>/dev/null || true
flutter doctor -v 2>&1 | head -30
echo ""

# ----------------------------------------------------------
# 7. Flutter-Projekt generieren (ios/ Ordner erstellen)
# ----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}→ Flutter-Projekt wird initialisiert…${NC}"
flutter create --org com.oldtimer . 2>&1 | tail -5
echo -e "${GREEN}✓ Flutter-Projekt initialisiert${NC}"

# ----------------------------------------------------------
# 8. Abhängigkeiten installieren
# ----------------------------------------------------------
echo -e "${YELLOW}→ Flutter-Pakete werden installiert…${NC}"
flutter pub get
echo -e "${GREEN}✓ Flutter-Pakete installiert${NC}"

# ----------------------------------------------------------
# 9. iOS Pods installieren
# ----------------------------------------------------------
echo -e "${YELLOW}→ CocoaPods werden installiert…${NC}"
cd ios
pod install
cd ..
echo -e "${GREEN}✓ CocoaPods installiert${NC}"

# ----------------------------------------------------------
# Fertig
# ----------------------------------------------------------
echo ""
echo "=========================================="
echo -e "${GREEN}  Setup abgeschlossen!${NC}"
echo "=========================================="
echo ""
echo "Nächster Schritt: Führe ./build.sh aus"
echo "oder öffne das Projekt manuell in Xcode:"
echo ""
echo "  open ios/Runner.xcworkspace"
echo ""
echo "In Xcode dann:"
echo "  1. Signing → eigenen Apple-Account wählen"
echo "  2. Bundle Identifier anpassen (z.B. com.deinname.oldtimerkmlog)"
echo "  3. Background Modes → 'Location updates' aktivieren"
echo "  4. iPhone anschließen → Run (▶)"
echo ""
