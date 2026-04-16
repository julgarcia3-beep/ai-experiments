# Daily Morning Briefing — Automation Spec Sheet

**System:** Claude Code Scheduled Task
**Schedule:** Daily, automated (runs each morning)
**Owner:** Julio Garcia, Executive Director — PACO Agency
**Last Verified:** April 15, 2026
**Status:** Active & Running

---

## Purpose

Deliver a unified, actionable morning briefing to Julio each day by (1) pushing a structured page to OneNote and (2) enriching it with live calendar, inbox, and task data so that the first 10 minutes of the day surface only what matters.

---

## Step-by-Step Execution

### Step 1 — OneNote Push

#### Cloud Mode (Primary)

Use MCP or Microsoft Graph API tools to create a OneNote page directly in the "Executive Working" section.

| Detail | Value |
|---|---|
| Target section | Executive Working |
| Page title format | `YYYY-MM-DD — Morning Briefing` |
| Auth method | Claude Code session (linked Microsoft account) |
| Content | Full assembled briefing from Steps 2-5 |

**Execution order:** Steps 2-5 run first to gather all data. The complete briefing is then pushed to OneNote as a single page in Step 6.

#### Local Fallback (Windows only)

**Tool:** `node createMorningBriefing.js`
**Path:** `C:\Users\user8\iCloudDrive\Documents\Work AI Hub\onenote-automation\`

| Detail | Value |
|---|---|
| Target section | Executive Working |
| Page title format | `YYYY-MM-DD — Morning Briefing` |
| Auth method | OAuth token (auto-refresh via Graph API) |
| Token expiry check | Refreshes if needed; reports expiry window |
| Log location | `…\onenote-automation\logs\` |

**Failure handling:**
- If auth fails: display device code login URL and code for manual re-auth
- If other failure: read logs, report the error, **do not retry more than once**

---

### Step 2 — Calendar Check

**Tool:** `mcp__ms-outlook-todo__list_calendar_events`
**Range:** Today `00:00:00` to `23:59:59` (full day)
**Max results:** 25

**Flagging logic:**

| Flag | Condition |
|---|---|
| Back-to-back | Gap between consecutive meetings < 15 minutes |
| External attendees | Any attendee email not ending in `@pacoagency.org` |
| No agenda | Meeting has no body/description text (prep needed) |
| Online vs. in-person | Noted from location field or Teams/Zoom links |
| Availability blocks | All-day blocks (e.g., travel, personal holds) noted |

**Output:** Meeting count, first meeting time (local EDT), flagged meetings listed by name.

---

### Step 3 — Inbox Triage

**Tool:** `mcp__ms-outlook-todo__list_emails`
**Filter:** `isRead eq false`
**Folder:** Inbox
**Top:** 25 (first page)

**Then:** `mcp__ms-outlook-todo__search_emails` — one query per strategic sender, run in **sequential batches of 2** to avoid stream timeouts:

| Batch | Sender | Search Term |
|---|---|---|
| 1 | Melissa | `from:melissa` |
| 1 | Vishnu | `from:vishnu` |
| 2 | Ron | `from:ron` |
| 2 | Rebecca | `from:rebecca` |
| 3 | Israel | `from:israel` |
| 3 | Christine | `from:christine` |
| 4 | Arely Hernandez | `from:arely.hernandez` |
| 4 | Gladys Negron | `from:gladys.negron` |

**Flagging logic:**

| Flag | Condition |
|---|---|
| High importance | Email marked `importance: high` |
| Strategic sender | Any email from the 8 senders above within last 24 hrs |
| Has attachment | Noted for action items |
| Financial/urgent | Subject keywords: payment, declined, invoice, overdue |

**Output:** Total unread count + any strategic sender alerts with subject lines.

---

### Step 4 — Task Check

**Tool:** `mcp__ms-outlook-todo__list_todo_lists` then `mcp__ms-outlook-todo__list_tasks`
**Filter:** `notCompleted`
**Top:** All active tasks (no hard limit)

**Flagging logic:**

| Flag | Condition |
|---|---|
| Overdue | Due date is before today's date |
| Due today | Due date equals today |
| High importance | Task flagged as high importance |

**Output:** Count of overdue tasks, count due today, any high-importance items by name.

---

### Step 5 — Status Summary

Final output assembled and displayed in the Claude session (and pushed to OneNote):

| Section | Content |
|---|---|
| OneNote Status | Success / Fail + page ID if created |
| Meetings | Count, first meeting time, any flags |
| Email | Unread count + strategic sender alerts |
| Tasks | Overdue + due-today counts |
| Top 3 Actions | Highest-priority items distilled from all three sources |

---

## Dependencies

| Dependency | Status |
|---|---|
| Claude Code (web, CLI, or desktop) | Required runtime environment |
| `ms-outlook-todo` MCP server | Must be connected for Steps 2-4 |
| Microsoft Graph API access | Required for OneNote page creation |
| OneNote — "Executive Working" section | Must exist in target notebook |
| Node.js runtime (local fallback only) | Required on Windows machine |
| `createMorningBriefing.js` script (local fallback only) | Must exist at local path |

---

## Known Limitations / Edge Cases

- **`list_todo_lists` API** currently returns a 400 error — tasks step is blocked until this is resolved. Likely a Microsoft To Do licensing or permissions issue.
- **`search_emails` in bulk parallel** — running 7+ simultaneous queries causes stream timeouts. Run sequentially in batches of 2.
- **Timezone:** All calendar times returned in UTC; converted to EDT (UTC-4) for display in briefing.
- **Vishnu travel blocks** — flagged as all-day calendar events; script does not currently parse these to auto-suppress meeting scheduling suggestions.

---

## Out of Scope

- This routine does **not** send emails or respond to messages on Julio's behalf
- It does **not** reschedule or create calendar events
- It does **not** complete or create tasks automatically
- It does **not** read email body content for full analysis (previews only)
- It does **not** push to SharePoint, Teams, or any channel other than OneNote

---

## Open Questions

| Question | Owner |
|---|---|
| Why is `list_todo_lists` returning a 400 error? | IT / Microsoft 365 admin |
| Should strategic sender list be expanded or updated? | Julio |
| Should the briefing also flag NJ 211 / emergency assistance requests? | Julio |
| Should search_emails run sequentially to avoid stream timeouts? | Automation developer |
| Should the OneNote page be updated with live data after the push, rather than before? | Julio / developer |

---

## Improvement Opportunities (Future Phase)

- Batch strategic sender searches to avoid parallel stream timeouts
- Parse calendar body text to detect Zoom/Teams links and label online vs. in-person automatically
- Resolve To Do API issue to re-enable full task triage
- Add a "yesterday's unread" carryover count to catch missed items from the prior day
- Add a weather/commute block for in-person meeting days
- Auto-detect EST vs EDT based on current date
- Add weekly summary aggregation from daily briefings
