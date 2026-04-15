# Research Loop Scan — Scheduled Task

> **Responsibility:** Scan Obsidian daily notes for research tags and dispatch each
> tagged topic to the `research-loop` pipeline skill.
>
> **Schedule:** Daily at 22:00 (10 PM), 7 days a week.
>
> **Boundary:** This file defines the *scanner*. The pipeline it dispatches to
> lives at `skills/research-loop/SKILL.md`. Two files, two responsibilities.

---

## Schedule

| Field | Value |
|---|---|
| Frequency | Daily (7 days — includes weekends) |
| Time | 22:00 local time |
| Runner | `scanner.sh` in this directory, installed via cron |

Running daily (not weekdays-only) ensures tags added on Friday evening, Saturday,
or Sunday are never missed.

---

## Scan Scope

Each run scans **today's daily note** and **yesterday's daily note**.

**Daily note path pattern:**
```
~/Documents/AI Data Hub/Obsidian/DailyNotes/<YYYY-MM-DD>.md
```

### Why two days?

- Catches tags added late in the day after a previous scan.
- Ensures nothing falls through if you edit yesterday's note today.
- Deduplication (see below) prevents double-processing.

---

## Tag Detection

The scanner searches for lines matching these tags:

| Tag | Context |
|---|---|
| `#research-for-work` | work |
| `#research-topic` | personal |
| `#research-later` | personal |
| `#deep-dive` | personal |

**Routing rule:** `#research-for-work` routes to context `work`. All other tags
route to context `personal`.

### Extraction

A tagged line looks like:
```
#research-topic LLM Fine-Tuning Best Practices
```

The scanner extracts:
1. **Tag** — the `#hashtag` token
2. **Topic** — everything after the tag on the same line, trimmed

Lines where the topic is empty after trimming are skipped.

---

## Deduplication

Before dispatching, the scanner deduplicates by **topic slug** (lowercase,
hyphens for spaces, special characters stripped).

Dedup sources:
1. **Cross-day:** If the same topic appears in both today's and yesterday's note,
   run it only once.
2. **Already-processed:** Check for an existing Obsidian research note at
   `~/Documents/AI Data Hub/Obsidian/Research/<YYYY-MM-DD>-<topic-slug>.md`.
   If the file exists for today's date, skip (already processed in a prior run or
   manual invocation).

---

## Dispatch

For each unique, non-duplicate topic, the scanner runs:

```bash
claude research-loop "<TOPIC>" --auto --<context> 2>&1 | tee -a "$LOG_FILE"
```

Topics are processed **sequentially**. Each invocation logs a completion summary
(see `research-loop` SKILL.md output format).

---

## Progress Logging

All output is logged to:
```
~/Documents/AI Data Hub/logs/research-loop-scan/<YYYY-MM-DD>.log
```

Log format:
```
[22:00:01] research-loop-scan START
[22:00:01] Scanning: ~/Documents/AI Data Hub/Obsidian/DailyNotes/2026-04-15.md
[22:00:01] Scanning: ~/Documents/AI Data Hub/Obsidian/DailyNotes/2026-04-14.md
[22:00:02] Found 3 tagged topics, 2 unique after dedup
[22:00:02] Skipped (already processed): "llm-fine-tuning"
[22:00:02] Processing 1/1: "Prompt Engineering Patterns" [personal]
[22:05:30] [research-loop] DONE "Prompt Engineering Patterns" ...
[22:05:30] research-loop-scan COMPLETE — 1 processed, 1 skipped, 0 failed
```

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Daily note file missing | Log warning, continue with other file |
| No tags found | Log "No research tags found", exit 0 |
| `research-loop` fails for a topic | Log error, continue to next topic |
| All topics fail | Exit 1, log summary |
| Scanner script itself errors | Cron captures stderr in log |

---

## Notification (Optional)

After all topics are processed, if the `notify-send` command is available,
send a desktop notification:

```
Research Loop Scan Complete
Processed: N | Skipped: M | Failed: F
```
