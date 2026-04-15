#!/bin/bash
# sync-to-obsidian.sh
# Syncs daily notes from Google Drive (Obsidian Sync/50-Daily) into the Obsidian vault.
# Runs via launchd every 5 minutes. Requires Google Drive for Desktop to be installed.
#
# Google Drive for Desktop syncs cloud files to:
#   ~/Library/CloudStorage/GoogleDrive-<email>/My Drive/
#
# This script copies any new or updated .md files from that location
# into the Obsidian vault's 50-Daily folder.

GDRIVE_SOURCE="$HOME/Library/CloudStorage/GoogleDrive-julgarcia3@gmail.com/My Drive/Obsidian Sync/50-Daily"
VAULT_TARGET="/Users/juliogarcia/Library/Mobile Documents/iCloud~md~obsidian/Documents/Julio 2nd Brain/50-Daily"
LOG_FILE="$HOME/Library/Logs/obsidian-sync.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Check if Google Drive folder exists
if [ ! -d "$GDRIVE_SOURCE" ]; then
    log "ERROR: Google Drive source not found: $GDRIVE_SOURCE"
    log "Make sure Google Drive for Desktop is installed and syncing."
    exit 1
fi

# Check if vault target exists
if [ ! -d "$VAULT_TARGET" ]; then
    log "ERROR: Obsidian vault target not found: $VAULT_TARGET"
    exit 1
fi

# Sync: copy .md files that are newer in source than target
SYNCED=0
for src_file in "$GDRIVE_SOURCE"/*.md; do
    [ -f "$src_file" ] || continue

    filename=$(basename "$src_file")
    dest_file="$VAULT_TARGET/$filename"

    # Copy if destination doesn't exist or source is newer
    if [ ! -f "$dest_file" ] || [ "$src_file" -nt "$dest_file" ]; then
        cp "$src_file" "$dest_file"
        SYNCED=$((SYNCED + 1))
        log "SYNCED: $filename"
    fi
done

if [ "$SYNCED" -gt 0 ]; then
    log "Sync complete: $SYNCED file(s) updated."
else
    # Only log every 30 min when idle (avoid log spam)
    MINUTE=$(date '+%M')
    if [ "$((MINUTE % 30))" -eq 0 ]; then
        log "No changes to sync."
    fi
fi

exit 0
