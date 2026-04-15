#!/usr/bin/env bash
# install.sh — Install (or update) the research-loop-scan cron job.
#
# Usage:
#   ./install.sh           # Install cron for 10 PM daily
#   ./install.sh --remove  # Remove the cron entry
#
# The cron job runs scanner.sh every day at 22:00 local time.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCANNER="${SCRIPT_DIR}/scanner.sh"
CRON_ID="# research-loop-scan"
CRON_SCHEDULE="0 22 * * *"
CRON_LINE="${CRON_SCHEDULE} ${SCANNER} ${CRON_ID}"

# ---------------------------------------------------------------------------
# Remove mode
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--remove" ]]; then
  if crontab -l 2>/dev/null | grep -qF "${CRON_ID}"; then
    crontab -l 2>/dev/null | grep -vF "${CRON_ID}" | crontab -
    echo "Removed research-loop-scan from crontab."
  else
    echo "No research-loop-scan entry found in crontab."
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Install / update
# ---------------------------------------------------------------------------

# Verify scanner exists and is executable
if [[ ! -x "${SCANNER}" ]]; then
  echo "ERROR: scanner.sh not found or not executable at ${SCANNER}"
  echo "Run: chmod +x ${SCANNER}"
  exit 1
fi

# Check if claude CLI is available
if ! command -v claude &>/dev/null; then
  echo "WARNING: 'claude' CLI not found in PATH."
  echo "The scanner dispatches topics via 'claude research-loop'."
  echo "Ensure claude is installed and in PATH before the first scheduled run."
fi

# Check if notebooklm CLI is available (optional dependency)
if [[ ! -x "${HOME}/.local/bin/notebooklm" ]]; then
  echo "NOTE: NotebookLM CLI not found at ~/.local/bin/notebooklm"
  echo "The pipeline will auto-fallback to --no-notebooklm mode if missing."
fi

# Remove existing entry if present, then add fresh
EXISTING_CRON=$(crontab -l 2>/dev/null || true)
NEW_CRON=$(echo "${EXISTING_CRON}" | grep -vF "${CRON_ID}" || true)

if [[ -n "${NEW_CRON}" ]]; then
  printf '%s\n%s\n' "${NEW_CRON}" "${CRON_LINE}" | crontab -
else
  echo "${CRON_LINE}" | crontab -
fi

echo "Installed research-loop-scan cron job:"
echo "  Schedule: Daily at 22:00 (10 PM)"
echo "  Command:  ${SCANNER}"
echo ""
echo "Verify with: crontab -l"
echo "Remove with: $0 --remove"
echo ""
echo "Required directories (created automatically on first run):"
echo "  ~/Documents/AI Data Hub/Obsidian/DailyNotes/   (your daily notes)"
echo "  ~/Documents/AI Data Hub/Obsidian/Research/      (output)"
echo "  ~/Documents/AI Data Hub/outputs/research/       (media files)"
echo "  ~/Documents/AI Data Hub/logs/research-loop-scan/ (logs)"
