#!/bin/bash

# ────────────────────────────────────────────────────────
# NotchSuperior — install.sh
# One-liner installer:
# curl -fsSL https://raw.githubusercontent.com/iamadarsha/NotchSuperior/main/install.sh | bash
# ────────────────────────────────────────────────────────

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}  NotchSuperior — Installer${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Require macOS 14+
OS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [ "$OS_MAJOR" -lt 14 ]; then
    echo -e "${RED}Error: NotchSuperior requires macOS 14.0 (Sonoma) or later.${NC}"
    exit 1
fi

DMG_URL="https://github.com/iamadarsha/NotchSuperior/releases/download/v1.0.1/NotchSuperior-v1.0.1.dmg"
TEMP_DMG="/tmp/NotchSuperior_install.dmg"
MOUNT_DIR="/tmp/NotchSuperiorMount"

echo -e "${BLUE}Downloading NotchSuperior...${NC}"
curl -L --progress-bar -o "$TEMP_DMG" "$DMG_URL"

echo -e "${BLUE}Mounting disk image...${NC}"
[ -d "$MOUNT_DIR" ] && hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

# Try /Applications first, fall back to ~/Applications
INSTALL_DIR="/Applications"
if [ ! -w "$INSTALL_DIR" ]; then
    INSTALL_DIR="$HOME/Applications"
    mkdir -p "$INSTALL_DIR"
    echo -e "${CYAN}Installing to ~/Applications (no write access to /Applications)${NC}"
fi

echo -e "${BLUE}Installing to ${INSTALL_DIR}...${NC}"
[ -d "$INSTALL_DIR/NotchSuperior.app" ] && rm -rf "$INSTALL_DIR/NotchSuperior.app"
cp -R "$MOUNT_DIR/NotchSuperior.app" "$INSTALL_DIR/"

# Remove macOS quarantine flag so the app opens without Gatekeeper warning
xattr -dr com.apple.quarantine "$INSTALL_DIR/NotchSuperior.app" 2>/dev/null || true

echo -e "${BLUE}Cleaning up...${NC}"
hdiutil detach "$MOUNT_DIR" -quiet || true
rm -f "$TEMP_DMG"

echo -e "${GREEN}Installed successfully!${NC}"
echo -e "${CYAN}Launching NotchSuperior...${NC}"
open "$INSTALL_DIR/NotchSuperior.app"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Done! Hover over the camera notch to get started.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
