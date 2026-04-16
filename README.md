# ai-experiments

Automation experiments for the AI Data Hub workflow.

## Research Loop Scan

Automated nightly scanner that reads Obsidian daily notes for research tags and
runs each tagged topic through the full research pipeline.

### How it works

1. **Scanner** (`scheduled-tasks/research-loop-scan/scanner.sh`) runs daily at 10 PM via cron.
2. It reads today's and yesterday's daily notes from `~/Documents/AI Data Hub/Obsidian/DailyNotes/`.
3. Lines tagged with `#research-for-work`, `#research-topic`, `#research-later`, or `#deep-dive` are extracted.
4. Each unique topic is dispatched to the **research-loop** pipeline skill, which:
   - Searches YouTube via firecrawl and scrapes transcripts
   - Generates an AI summary (executive summary, key findings, sources)
   - Optionally creates a NotebookLM podcast + slides
   - Writes 3 Obsidian files (research note, source index, raw payload)
   - Backs up to Notion

### Tag routing

| Tag | Context |
|---|---|
| `#research-for-work` | work (includes PACO Relevance section) |
| `#research-topic` | personal |
| `#research-later` | personal |
| `#deep-dive` | personal |

### Setup — Local (cron)

```bash
cd scheduled-tasks/research-loop-scan
./install.sh          # installs cron for 10 PM daily
./install.sh --remove # removes the cron entry
```

### Setup — Cloud (GitHub Actions)

The workflow runs automatically at 10 PM UTC daily. To use it:

1. Sync your Obsidian daily notes to `daily-notes/` in this repo (see `daily-notes/SYNC.md`).
2. The Action scans for tags, generates topic manifests, and commits results to `research-output/`.
3. Trigger manually via **Actions > Research Loop Scan > Run workflow** (supports dry-run).

### File structure

```
.github/workflows/
  research-loop-scan.yml   # Cloud scheduler (GitHub Actions)

scheduled-tasks/research-loop-scan/
  SKILL.md           # Scanner spec (schedule, tags, dedup, modes)
  scanner.sh         # The executable scanner (local + cloud modes)
  install.sh         # Local cron installer/uninstaller
  test_scanner.sh    # Integration test suite (10 tests, 22 assertions)

skills/research-loop/
  SKILL.md           # Pipeline spec (firecrawl, NotebookLM, Obsidian, Notion)

daily-notes/         # Cloud mode: sync Obsidian daily notes here
  SYNC.md            # Sync instructions
research-output/     # Cloud mode: generated manifests (auto-committed)
logs/                # Cloud mode: scanner logs (auto-committed)
```

### Logs

- **Local:** `~/Documents/AI Data Hub/logs/research-loop-scan/<YYYY-MM-DD>.log`
- **Cloud:** `logs/research-loop-scan/<YYYY-MM-DD>.log` (committed to repo) + GitHub Actions run summary
