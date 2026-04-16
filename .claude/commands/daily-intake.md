Read the full skill spec at `routines/daily/daily-intake.md` in this repo and execute it now.

**Context for this run:**
- Today's date: use the current date
- Current time: use the current time to determine mode (morning < 12, midday 12–5, evening > 5)
- Environment: local Claude Code session with full MCP access

**Available MCP tools — use all that apply:**
- `mcp__ms365__outlook_calendar_search` — today's Outlook events
- `mcp__ms365__outlook_email_search` — last 24h email for triage
- `mcp__Google-Drive__create_file` — push note to Google Drive (folder ID: `1b6ySYjIS9fjESe0uJy9ZMjqLGAzXOUBv`)
- `mcp__Google-Drive__search_files` — check if today's note already exists
- `mcp__reclaim__reclaim_list_events` — Reclaim calendar events
- `mcp__mstodo__mstodo_list_tasks` / `mcp__mstodo__mstodo_get_due_tasks` — MS To Do tasks
- `mcp__obsidian-vault__obsidian_read_file` — read Obsidian vault files (daily notes, projects, golf stats, templates)
- `mcp__obsidian-vault__obsidian_write_file` — write daily note directly to vault
- `mcp__obsidian-vault__obsidian_list_folder` — list vault folders
- `mcp__obsidian-vault__obsidian_search` — search vault content

**Execution order:**
1. Read the spec (`routines/daily/daily-intake.md`)
2. Check if today's note exists in the vault (`50-Daily/YYYY-MM-DD.md`)
3. Gather context in parallel: calendar, email, carry-overs (last 2-3 daily notes), active projects, golf/fitness, MS To Do tasks
4. Build or update the daily note following the spec exactly
5. Write to Obsidian vault AND push to Google Drive
6. No conversational summary — the note is the output
