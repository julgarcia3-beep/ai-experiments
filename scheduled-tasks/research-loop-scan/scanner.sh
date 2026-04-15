#!/usr/bin/env bash
# research-loop-scan — scanner.sh
# Scans Obsidian daily notes for research tags, deduplicates, and dispatches
# each topic to the research-loop pipeline skill.
#
# Schedule: Daily at 22:00 via cron (see install.sh)
# Docs:     scheduled-tasks/research-loop-scan/SKILL.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
OBSIDIAN_DAILY="${HOME}/Documents/AI Data Hub/Obsidian/DailyNotes"
OBSIDIAN_RESEARCH="${HOME}/Documents/AI Data Hub/Obsidian/Research"
OUTPUT_DIR="${HOME}/Documents/AI Data Hub/outputs/research"
LOG_DIR="${HOME}/Documents/AI Data Hub/logs/research-loop-scan"

TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)

mkdir -p "${LOG_DIR}" "${OUTPUT_DIR}" "${OBSIDIAN_RESEARCH}"
LOG_FILE="${LOG_DIR}/${TODAY}.log"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() {
  local ts
  ts=$(date +"%H:%M:%S")
  echo "[${ts}] $*" | tee -a "${LOG_FILE}"
}

to_slug() {
  # lowercase, spaces to hyphens, strip non-alphanumeric/hyphens
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g; s/[^a-z0-9-]//g; s/--*/-/g; s/^-//; s/-$//'
}

tag_to_context() {
  local tag="$1"
  if [[ "${tag}" == "#research-for-work" ]]; then
    echo "work"
  else
    echo "personal"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "research-loop-scan START"

# Collect daily note files to scan (today + yesterday)
declare -a NOTE_FILES=()
for dt in "${TODAY}" "${YESTERDAY}"; do
  note_path="${OBSIDIAN_DAILY}/${dt}.md"
  if [[ -f "${note_path}" ]]; then
    NOTE_FILES+=("${note_path}")
    log "Scanning: ${note_path}"
  else
    log "WARNING: Daily note not found — ${note_path}"
  fi
done

if [[ ${#NOTE_FILES[@]} -eq 0 ]]; then
  log "No daily note files found. Exiting."
  exit 0
fi

# ---------------------------------------------------------------------------
# Extract tagged lines
# Tag pattern: #research-for-work | #research-topic | #research-later | #deep-dive
# ---------------------------------------------------------------------------
declare -A TOPICS=()   # slug -> "tag|topic"
declare -a ORDER=()    # preserve discovery order

TAG_PATTERN='^[[:space:]]*(#research-for-work|#research-topic|#research-later|#deep-dive)[[:space:]]+'

for note_file in "${NOTE_FILES[@]}"; do
  while IFS= read -r line; do
    # Extract tag and topic
    tag=$(echo "${line}" | grep -oE '(#research-for-work|#research-topic|#research-later|#deep-dive)' | head -1)
    topic=$(echo "${line}" | sed -E "s/^[[:space:]]*(#research-for-work|#research-topic|#research-later|#deep-dive)[[:space:]]+//" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Skip empty topics
    if [[ -z "${topic}" ]]; then
      continue
    fi

    slug=$(to_slug "${topic}")

    # Dedup: skip if we already have this slug
    if [[ -n "${TOPICS[${slug}]+x}" ]]; then
      continue
    fi

    TOPICS["${slug}"]="${tag}|${topic}"
    ORDER+=("${slug}")
  done < <(grep -E "${TAG_PATTERN}" "${note_file}" 2>/dev/null || true)
done

TOTAL_FOUND=${#ORDER[@]}
log "Found ${TOTAL_FOUND} tagged topics (unique after cross-day dedup)"

if [[ ${TOTAL_FOUND} -eq 0 ]]; then
  log "No research tags found. Exiting."
  exit 0
fi

# ---------------------------------------------------------------------------
# Filter out already-processed topics (today's date)
# ---------------------------------------------------------------------------
declare -a TO_PROCESS=()
SKIPPED=0

for slug in "${ORDER[@]}"; do
  existing="${OBSIDIAN_RESEARCH}/${TODAY}-${slug}.md"
  if [[ -f "${existing}" ]]; then
    log "Skipped (already processed): \"${slug}\""
    ((SKIPPED++))
  else
    TO_PROCESS+=("${slug}")
  fi
done

PROCESS_COUNT=${#TO_PROCESS[@]}
log "${PROCESS_COUNT} to process, ${SKIPPED} skipped (already processed)"

if [[ ${PROCESS_COUNT} -eq 0 ]]; then
  log "All topics already processed. Exiting."
  exit 0
fi

# ---------------------------------------------------------------------------
# Dispatch to research-loop pipeline
# ---------------------------------------------------------------------------
PROCESSED=0
FAILED=0

for i in "${!TO_PROCESS[@]}"; do
  slug="${TO_PROCESS[$i]}"
  entry="${TOPICS[${slug}]}"
  tag="${entry%%|*}"
  topic="${entry#*|}"
  context=$(tag_to_context "${tag}")
  idx=$((i + 1))

  log "Processing ${idx}/${PROCESS_COUNT}: \"${topic}\" [${context}]"
  start_time=$(date +%s)

  if claude research-loop "${topic}" --auto --"${context}" 2>&1 | tee -a "${LOG_FILE}"; then
    end_time=$(date +%s)
    duration=$(( end_time - start_time ))
    log "DONE \"${topic}\" (${duration}s)"
    ((PROCESSED++))
  else
    end_time=$(date +%s)
    duration=$(( end_time - start_time ))
    log "FAILED \"${topic}\" after ${duration}s"
    ((FAILED++))
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "research-loop-scan COMPLETE — ${PROCESSED} processed, ${SKIPPED} skipped, ${FAILED} failed"

# Desktop notification (optional, non-fatal)
if command -v notify-send &>/dev/null; then
  notify-send "Research Loop Scan Complete" \
    "Processed: ${PROCESSED} | Skipped: ${SKIPPED} | Failed: ${FAILED}" \
    2>/dev/null || true
fi

# Exit non-zero only if ALL topics failed
if [[ ${PROCESSED} -eq 0 && ${FAILED} -gt 0 ]]; then
  exit 1
fi

exit 0
