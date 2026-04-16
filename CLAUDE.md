# CLAUDE.md

## Project: PACO Agency — AI Experiments

This repository contains AI automation experiments and Claude Code routines for Julio Garcia, Executive Director, PACO Agency.

## Repository Structure

- `/index.html` — Smart Packet Processor (standalone tool)
- `/routines/` — Claude Code scheduled task routines
  - `/routines/morning-briefing/` — Daily Morning Briefing routine

## MCP Tools Available

This project uses the `ms-outlook-todo` MCP server for Microsoft 365 integration:
- `mcp__ms-outlook-todo__list_calendar_events` — Calendar events
- `mcp__ms-outlook-todo__list_emails` — Email inbox
- `mcp__ms-outlook-todo__search_emails` — Email search
- `mcp__ms-outlook-todo__list_todo_lists` — Task lists (known 400 error)
- `mcp__ms-outlook-todo__list_tasks` — Tasks within a list

## Conventions

- Routine prompts live in `/routines/<routine-name>/<routine-name>.md`
- Each routine directory contains a `SPEC.md` with full specifications
- Routines are read-only: they gather and report but never modify data
- All times displayed in EDT (UTC-4) unless otherwise noted
