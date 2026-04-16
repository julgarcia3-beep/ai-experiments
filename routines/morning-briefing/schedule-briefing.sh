#!/usr/bin/env bash
# =============================================================================
# Morning Briefing — Cron Wrapper (Linux/macOS)
# Schedule: 7:10 AM ET, Monday–Friday
#
# SETUP (one-time):
#   crontab -e
#   # If system timezone is ET:
#   10 7 * * 1-5 /path/to/ai-experiments/routines/morning-briefing/schedule-briefing.sh
#   # If system timezone is UTC:
#   10 11 * * 1-5 /path/to/ai-experiments/routines/morning-briefing/schedule-briefing.sh
#
# =============================================================================

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROUTINE_FILE="$SCRIPT_DIR/morning-briefing.md"
LOG_DIR="$SCRIPT_DIR/logs"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
LOG_FILE="$LOG_DIR/briefing-$TIMESTAMP.log"

# --- Ensure log directory exists ---
mkdir -p "$LOG_DIR"

# --- Check if routine file exists ---
if [ ! -f "$ROUTINE_FILE" ]; then
    echo "ERROR: Routine file not found at $ROUTINE_FILE" | tee "$LOG_FILE"
    exit 1
fi

# --- Run Claude Code with the routine ---
echo "Starting Morning Briefing at $(date '+%Y-%m-%d %H:%M:%S')" | tee "$LOG_FILE"

cat "$ROUTINE_FILE" | claude -p \
    --add-dir "$REPO_DIR" \
    2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[1]:-0}

if [ "$EXIT_CODE" -ne 0 ]; then
    echo "EXIT CODE: $EXIT_CODE" | tee -a "$LOG_FILE"
    echo "Claude Code exited with code $EXIT_CODE. Check log: $LOG_FILE" >&2
    exit "$EXIT_CODE"
else
    echo "Morning Briefing completed successfully." | tee -a "$LOG_FILE"
fi
