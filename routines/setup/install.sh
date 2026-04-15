#!/bin/bash
# install.sh
# Sets up the Google Drive → Obsidian sync on macOS.
# Run this once on your Mac to install everything.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/Scripts"
PLIST_DIR="$HOME/Library/LaunchAgents"

echo "=== Obsidian Sync — Install ==="
echo ""

# 1. Create Scripts directory
echo "[1/4] Creating $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# 2. Copy sync script
echo "[2/4] Installing sync-to-obsidian.sh..."
cp "$SCRIPT_DIR/sync-to-obsidian.sh" "$INSTALL_DIR/sync-to-obsidian.sh"
chmod +x "$INSTALL_DIR/sync-to-obsidian.sh"

# 3. Install launchd plist
echo "[3/4] Installing launchd plist..."
mkdir -p "$PLIST_DIR"
cp "$SCRIPT_DIR/com.julio.obsidian-sync.plist" "$PLIST_DIR/com.julio.obsidian-sync.plist"

# 4. Load the agent
echo "[4/4] Loading launchd agent..."
launchctl unload "$PLIST_DIR/com.julio.obsidian-sync.plist" 2>/dev/null || true
launchctl load "$PLIST_DIR/com.julio.obsidian-sync.plist"

echo ""
echo "=== Done ==="
echo ""
echo "The sync is now running every 5 minutes."
echo "  Script:  $INSTALL_DIR/sync-to-obsidian.sh"
echo "  Plist:   $PLIST_DIR/com.julio.obsidian-sync.plist"
echo "  Logs:    ~/Library/Logs/obsidian-sync.log"
echo ""
echo "Prerequisites:"
echo "  - Google Drive for Desktop must be installed and signed in as julgarcia3@gmail.com"
echo "  - The 'Obsidian Sync/50-Daily' folder must exist in Google Drive (already created)"
echo ""
echo "To test manually:  bash ~/Scripts/sync-to-obsidian.sh"
echo "To check status:   launchctl list | grep obsidian"
echo "To stop:           launchctl unload ~/Library/LaunchAgents/com.julio.obsidian-sync.plist"
echo "To view logs:      tail -f ~/Library/Logs/obsidian-sync.log"
