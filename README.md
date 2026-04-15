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

### Setup

```bash
cd scheduled-tasks/research-loop-scan
./install.sh          # installs cron for 10 PM daily
./install.sh --remove # removes the cron entry
```

### File structure

```
scheduled-tasks/research-loop-scan/
  SKILL.md       # Scanner spec (schedule, tags, dedup, dispatch)
  scanner.sh     # The executable scanner script
  install.sh     # Cron installer/uninstaller

skills/research-loop/
  SKILL.md       # Pipeline spec (firecrawl, NotebookLM, Obsidian, Notion)
```

### Logs

Scanner logs are written to `~/Documents/AI Data Hub/logs/research-loop-scan/<YYYY-MM-DD>.log`.
