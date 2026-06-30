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

# ----------------------------------------------------------
# Homebrew PATH laden (Apple Silicon + Intel)
# ----------------------------------------------------------
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

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

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
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
    echo -e "${GREEN}✓ CocoaPods ist installiert${NC}"
else
    echo -e "${YELLOW}→ CocoaPods wird installiert…${NC}"
    brew install cocoapods
    echo -e "${GREEN}✓ CocoaPods installiert${NC}"
fi

# ----------------------------------------------------------
# 5. Flutter SDK prüfen / installieren
# ----------------------------------------------------------
if command -v flutter &>/dev/null; then
    echo -e "${GREEN}✓ Flutter ist installiert${NC}"
else
    echo -e "${YELLOW}→ Flutter wird installiert…${NC}"
    brew install --cask flutter

    # Flutter-Pfad finden und zum PATH hinzufügen
    FLUTTER_PATH="$(find $(brew --prefix)/Caskroom/flutter -name flutter -type f 2>/dev/null | grep '/bin/flutter$' | head -1)"
    if [[ -n "$FLUTTER_PATH" ]]; then
        FLUTTER_BIN_DIR="$(dirname "$FLUTTER_PATH")"
        export PATH="$PATH:$FLUTTER_BIN_DIR"

        # Dauerhaft in .zprofile speichern
        if ! grep -q "flutter" ~/.zprofile 2>/dev/null; then
            echo "export PATH=\"\$PATH:$FLUTTER_BIN_DIR\"" >> ~/.zprofile
        fi
    fi

    echo -e "${GREEN}✓ Flutter installiert${NC}"
fi

# Sicherstellen dass flutter jetzt im PATH ist
if ! command -v flutter &>/dev/null; then
    FLUTTER_PATH="$(find /opt/homebrew/Caskroom/flutter /usr/local/Caskroom/flutter -name flutter -type f 2>/dev/null | grep '/bin/flutter$' | head -1)"
    if [[ -n "$FLUTTER_PATH" ]]; then
        export PATH="$PATH:$(dirname "$FLUTTER_PATH")"
    fi
fi

if ! command -v flutter &>/dev/null; then
    echo -e "${RED}✗ Flutter konnte nicht gefunden werden!${NC}"
    echo "  Schließe das Terminal, öffne ein neues und führe ./setup.sh erneut aus."
    exit 1
fi

# ----------------------------------------------------------
# 6. Flutter Doctor
# ----------------------------------------------------------
echo ""
echo -e "${YELLOW}→ Prüfe Flutter-Umgebung…${NC}"
flutter doctor 2>&1 | head -20
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
