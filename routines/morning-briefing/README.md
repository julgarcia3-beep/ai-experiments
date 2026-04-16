# Morning Briefing Routine

Daily executive morning briefing for Julio Garcia, Executive Director of PACO Agency.

## What It Does

Runs as a Claude Code scheduled task each morning to gather and present:
- Today's calendar events with smart flags (back-to-back, external attendees, no agenda)
- Inbox triage with priority email surfacing from 8 strategic senders
- Task status (overdue, due today, high importance)
- Top 3 priorities synthesized from all sources
- OneNote page creation in the "Executive Working" section

## Schedule

**7:10 AM ET, Monday through Friday**

### Windows (Task Scheduler) — Recommended

1. Open Task Scheduler (`taskschd.msc`)
2. **Create Basic Task** > Name: `PACO Morning Briefing`
3. **Trigger:** Daily at **7:10 AM**
   - Advanced settings: check Monday through Friday only
4. **Action:** Start a Program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\Users\user8\iCloudDrive\Documents\Work AI Hub\ai-experiments\routines\morning-briefing\schedule-briefing.ps1"`
5. **Conditions:** Check "Run whether user is logged on or not" for unattended execution

### Linux/macOS (Cron)

```bash
# If system timezone is ET:
crontab -e
10 7 * * 1-5 /path/to/ai-experiments/routines/morning-briefing/schedule-briefing.sh

# If system timezone is UTC (7:10 AM ET = 11:10 UTC):
10 11 * * 1-5 /path/to/ai-experiments/routines/morning-briefing/schedule-briefing.sh
```

### Logs

Both scripts write timestamped logs to `routines/morning-briefing/logs/` (auto-created on first run, git-ignored).

## Dependencies

| Dependency | Required |
|---|---|
| Claude Code CLI | Yes — `claude` must be in PATH |
| `ms-outlook-todo` MCP server | Yes — provides calendar, email, and task access |
| Microsoft Graph API access | Yes — for OneNote page creation |
| OneNote "Executive Working" section | Yes — target for briefing page |

## Files

| File | Purpose |
|---|---|
| `morning-briefing.md` | The executable routine prompt (Claude Code runs this) |
| `schedule-briefing.ps1` | Windows Task Scheduler wrapper script |
| `schedule-briefing.sh` | Linux/macOS cron wrapper script |
| `SPEC.md` | Full specification and reference documentation |
| `README.md` | This file |

## Read-Only Guarantee

This routine only reads data. It will never send emails, create events, complete tasks, or modify any data on Julio's behalf.
