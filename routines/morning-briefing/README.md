# Morning Briefing Routine

Daily executive morning briefing for Julio Garcia, Executive Director of PACO Agency.

## What It Does

Runs as a Claude Code scheduled task each morning to gather and present:
- Today's calendar events with smart flags (back-to-back, external attendees, no agenda)
- Inbox triage with priority email surfacing from 8 strategic senders
- Task status (overdue, due today, high importance)
- Top 3 priorities synthesized from all sources
- OneNote page creation in the "Executive Working" section

## How to Use

Register `morning-briefing.md` as a Claude Code scheduled task (daily).

## Dependencies

| Dependency | Required |
|---|---|
| Claude Code (web, CLI, or desktop) | Yes |
| `ms-outlook-todo` MCP server | Yes — provides calendar, email, and task access |
| Microsoft Graph API access | Yes — for OneNote page creation |
| OneNote "Executive Working" section | Yes — target for briefing page |

## Files

| File | Purpose |
|---|---|
| `morning-briefing.md` | The executable routine prompt (Claude Code runs this) |
| `SPEC.md` | Full specification and reference documentation |
| `README.md` | This file |

## Read-Only Guarantee

This routine only reads data. It will never send emails, create events, complete tasks, or modify any data on Julio's behalf.
