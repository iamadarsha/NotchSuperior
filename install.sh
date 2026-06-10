#!/bin/bash

# ────────────────────────────────────────────────────────
# NotchSuperior — install.sh
# One-liner to run:
# curl -fsSL https://raw.githubusercontent.com/iamadarsha/NotchSuperior/main/install.sh | bash
# ────────────────────────────────────────────────────────

set -e

# ANSI styling
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 Starting NotchSuperior installation...${NC}"

# Define installer targets
DMG_URL="https://github.com/iamadarsha/NotchSuperior/releases/download/v2.7.3/NotchSuperior.dmg"
TEMP_DMG="/tmp/NotchSuperior.dmg"
MOUNT_DIR="/tmp/NotchSuperiorMount"

# Download the DMG
echo -e "${BLUE}📥 Downloading NotchSuperior DMG...${NC}"
curl -L -# -o "$TEMP_DMG" "$DMG_URL"

# Mount the DMG
echo -e "${BLUE}📦 Mounting installer...${NC}"
if [ -d "$MOUNT_DIR" ]; then
    rm -rf "$MOUNT_DIR"
fi
mkdir -p "$MOUNT_DIR"
hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

# Copy to Applications
echo -e "${BLUE}🚚 Installing to Applications folder...${NC}"
if [ -d "/Applications/NotchSuperior.app" ]; then
    echo -e "${RED}⚠️  Existing NotchSuperior installation found. Overwriting...${NC}"
    rm -rf "/Applications/NotchSuperior.app"
fi
cp -R "$MOUNT_DIR/NotchSuperior.app" "/Applications/"

# Unmount and clean up
echo -e "${BLUE}🧹 Cleaning up installer files...${NC}"
hdiutil detach "$MOUNT_DIR" -quiet || true
rm -rf "$MOUNT_DIR"
rm -f "$TEMP_DMG"

# Completion
echo -e "${GREEN}🎉 NotchSuperior has been successfully installed in your /Applications folder!${NC}"
echo -e "${CYAN}🚀 Launching NotchSuperior...${NC}"
open "/Applications/NotchSuperior.app"

echo -e "${GREEN}✨ All set! Enjoy your NotchSuperior experience 🫶${NC}"
