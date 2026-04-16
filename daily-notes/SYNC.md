# Daily Notes Sync

This directory is where the cloud scanner reads daily notes from.

## How to sync your Obsidian daily notes here

### Option 1: Obsidian Git plugin (recommended)

1. Install the [Obsidian Git](https://github.com/denolehov/obsidian-git) plugin.
2. Configure it to push your vault to this repo.
3. Map your DailyNotes folder to `daily-notes/` in this repo.

### Option 2: Manual push

Copy today's daily note into this directory and push:

```bash
cp ~/Documents/AI\ Data\ Hub/Obsidian/DailyNotes/2026-04-15.md daily-notes/
git add daily-notes/ && git commit -m "sync daily note" && git push
```

### Option 3: Automated sync script

Add a cron job or a pre-push hook that copies your daily notes:

```bash
# Copy today's and yesterday's notes before each scan
cp ~/Documents/AI\ Data\ Hub/Obsidian/DailyNotes/$(date +%Y-%m-%d).md daily-notes/ 2>/dev/null || true
cp ~/Documents/AI\ Data\ Hub/Obsidian/DailyNotes/$(date -d yesterday +%Y-%m-%d).md daily-notes/ 2>/dev/null || true
```

## File format

Daily notes should be named `YYYY-MM-DD.md` and contain research tags like:

```
#research-for-work LLM Fine-Tuning Best Practices
#research-topic Prompt Engineering Patterns
#deep-dive Local RAG Pipelines
```
