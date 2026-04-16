# Research Loop — Pipeline Skill

> **Responsibility:** Execute the full research pipeline for a single topic.
> This skill is called by the `research-loop-scan` scanner — not invoked directly by cron.

---

## Invocation

```
claude research-loop "<TOPIC>" [flags]
```

### Flags

| Flag | Description |
|---|---|
| `--work` | Set context to **work** (affects PACO Relevance section in output) |
| `--personal` | Set context to **personal** (default) |
| `--no-notebooklm` | Skip NotebookLM podcast/slides generation (Step 3) |
| `--auto` | Autonomous mode for scheduled runs. Defaults to **personal** unless `--work` flag is also set or the triggering tag is `#research-for-work`. |
| `--dry-run` | Log what would happen without executing any steps |

---

## Pipeline Steps

### Step 1 — YouTube + Firecrawl Search

1. Search YouTube for `"<TOPIC>"` via firecrawl.
2. Collect top 5 results: title, channel, URL, description snippet.
3. For each result, run `firecrawl scrape <URL>` to extract transcript/content.
4. Aggregate into a structured research payload.

**Error handling:** If firecrawl is unavailable or returns zero results, log the error and continue to Step 2 with an empty payload. The Obsidian note will include a `firecrawl-failed: true` frontmatter flag.

### Step 2 — AI Summary Generation

1. Feed the aggregated payload into Claude for synthesis.
2. Produce:
   - **Executive summary** (3-5 sentences)
   - **Key findings** (bulleted)
   - **Source list** with links
   - **PACO Relevance** section (only if context = work)

### Step 3 — NotebookLM Podcast + Slides

1. Check that `~/.local/bin/notebooklm` exists and is executable.
   - If missing: log warning, set `--no-notebooklm` implicitly, skip to Step 4.
2. Run: `~/.local/bin/notebooklm generate --topic "<TOPIC>" --format podcast,slides`
3. Download outputs to explicit paths:
   - Podcast: `~/Documents/AI Data Hub/outputs/research/<topic-slug>-podcast.mp3`
   - Slides: `~/Documents/AI Data Hub/outputs/research/<topic-slug>-slides.pdf`
4. If generation fails or times out (5 min), fall back to `--no-notebooklm` mode and continue.

**Topic slug:** lowercase, hyphens for spaces, strip special characters. E.g., `"LLM Fine-Tuning"` -> `llm-fine-tuning`.

### Step 4 — Obsidian Output (3 Files)

All files written under `~/Documents/AI Data Hub/Obsidian/Research/`.

#### File A — Research Note

**Path:** `~/Documents/AI Data Hub/Obsidian/Research/<YYYY-MM-DD>-<topic-slug>.md`

```yaml
---
title: "Research Loop — <TOPIC>"
date: <YYYY-MM-DD>
context: <work|personal>
tags:
  - research
  - <triggering-tag>
sources: <number of sources>
firecrawl-failed: <true|false>
notebooklm: <true|false>
---
```

**Body sections:**
1. `## Executive Summary`
2. `## Key Findings`
3. `## Sources` (linked list)
4. `## PACO Relevance` (only if context = work)
5. `## Media` (links to podcast/slides if generated)

#### File B — Source Index

**Path:** `~/Documents/AI Data Hub/Obsidian/Research/<YYYY-MM-DD>-<topic-slug>-sources.md`

A flat list of all URLs scraped, with metadata (title, channel/author, scrape date).

#### File C — Raw Payload

**Path:** `~/Documents/AI Data Hub/Obsidian/Research/<YYYY-MM-DD>-<topic-slug>-raw.json`

The full firecrawl + summary payload as structured JSON for reproducibility.

### Step 5 — Notion Backup

1. Create a new Notion page titled: `Research Loop — <TOPIC> — <YYYY-MM-DD>`
2. Parent: Research database in Notion workspace.
3. Body: mirror of File A content (executive summary, key findings, sources, PACO Relevance if applicable).
4. Properties: `date`, `context`, `tags`, `source-count`.

**Error handling:** If Notion API fails, log the error. Do not retry — the Obsidian files are the primary record.

---

## Output Summary

On completion, log:
```
[research-loop] DONE "<TOPIC>"
  Context:     <work|personal>
  Sources:     <N>
  NotebookLM:  <yes|skipped|failed>
  Obsidian:    3 files written
  Notion:      <synced|failed>
  Duration:    <Xm Ys>
```
