# Daily Morning Briefing

You are running a scheduled morning briefing routine for **Julio Garcia, Executive Director of PACO Agency**. Gather information from multiple sources, analyze it, and present a consolidated executive summary.

---

## Critical Rules

1. **READ-ONLY.** Do NOT send emails, create events, complete tasks, reschedule meetings, or modify any data. You only read and report.
2. **Do NOT read full email bodies.** Use only subject, sender, importance, and metadata.
3. **Do NOT skip steps.** If a step fails, record the failure and continue to the next step.
4. **Timezone: EDT (UTC-4).** All calendar APIs return UTC. Convert every timestamp to Eastern Daylight Time before displaying.
5. **Use today's date** for all API calls (YYYY-MM-DD format).
6. **Execute steps in order.** Gather all data (Steps 1-4) first, then assemble the summary (Step 5), then push to OneNote (Step 6).

---

## Step 1: Calendar Check

Call the MCP tool to retrieve today's calendar events.

**Tool:** `mcp__ms-outlook-todo__list_calendar_events`
**Parameters:**
- Date range: today 00:00:00 to 23:59:59 (UTC)
- Max results: 25

### Processing

For every event returned, convert start and end times from UTC to EDT (subtract 4 hours). Sort events chronologically. Then evaluate these flags:

**Back-to-Back** — If the gap between this event's start and the previous event's end is less than 15 minutes, flag both events.

**External Attendees** — Check all attendee email addresses. Any address that does NOT end in `@pacoagency.org` marks this meeting as having external attendees. Note the external domains.

**No Agenda** — If the event body or description is empty or missing, flag as "no agenda — prep needed."

**Online vs In-Person** — If the event has an online meeting URL (Teams, Zoom, Google Meet, WebEx) or the location contains "teams", "zoom", or a URL, mark as "Online." Otherwise mark as "In-Person." Include the location if populated.

**Focus/Block Time** — If the event is an all-day event, or the title contains words like "block", "focus", "hold", "busy", "no meetings", "OOO", "travel", or "personal" (case-insensitive), mark as an availability block rather than a meeting.

### If the tool call fails

Record: `Calendar: FAILED — [error message]` and continue to Step 2.

---

## Step 2: Inbox Triage

This step has two parts. Complete Part A first, then Part B.

### Part A: Unread Inbox Scan

**Tool:** `mcp__ms-outlook-todo__list_emails`
**Parameters:**
- Filter: unread only (`isRead eq false`)
- Folder: Inbox
- Top: 25

For each email, evaluate these flags:

**High Importance** — Email is marked `importance: high`.

**Strategic Sender** — The sender matches any of these people (check both display name and email address):
1. Melissa
2. Vishnu
3. Ron
4. Rebecca
5. Israel
6. Christine
7. Arely Hernandez (also match: Arely Hernandez, arely.hernandez)
8. Gladys Negron (also match: Gladys Negron, gladys.negron)

**Has Attachment** — Email has one or more attachments.

**Action/Financial Keywords** — Subject line contains any of (case-insensitive): "urgent", "asap", "action required", "deadline", "overdue", "payment", "invoice", "budget", "grant", "contract", "approval", "approve", "sign", "signature", "declined".

Record the total unread count and all flagged emails with their flags.

### Part B: Strategic Sender Search

Search for recent emails from the 8 strategic senders. Run these in **sequential batches of 2** to avoid stream timeouts. Wait for each batch to complete before starting the next.

**Tool:** `mcp__ms-outlook-todo__search_emails`

**Batch 1:**
- Query: `from:melissa`
- Query: `from:vishnu`

**Batch 2:**
- Query: `from:ron`
- Query: `from:rebecca`

**Batch 3:**
- Query: `from:israel`
- Query: `from:christine`

**Batch 4:**
- Query: `from:arely.hernandez`
- Query: `from:gladys.negron`

For each result, apply the same flags as Part A.

### Deduplication

If an email appears in both Part A and Part B results (same message ID, or same subject + sender + timestamp), keep only one entry and merge the flags.

### If any search call fails

Note which sender search failed and continue with the remaining searches. Do not abort the entire step.

---

## Step 3: Task Check

> **KNOWN ISSUE:** The `list_todo_lists` tool currently returns a 400 error. Attempt the call anyway — it may have been fixed. Be prepared for failure.

### Step 3a: Get Task Lists

**Tool:** `mcp__ms-outlook-todo__list_todo_lists`

- **If this succeeds:** proceed to Step 3b for each list returned.
- **If this returns a 400 or any error:** Record the following and skip to Step 4:

```
Tasks: Unavailable — the task list API returned an error (400).
This is a known issue. Task review skipped for today.
Manual check recommended at https://to-do.office.com
```

### Step 3b: Get Tasks (only if 3a succeeded)

For each task list from Step 3a:

**Tool:** `mcp__ms-outlook-todo__list_tasks`
**Parameters:**
- list_id: [from Step 3a]
- Status filter: not completed

For each task, evaluate:

**Overdue** — Due date is before today.

**Due Today** — Due date equals today.

**High Importance** — Marked as high importance or priority.

---

## Step 4: Assemble Data

At this point you have collected data from Steps 1-3. Before producing the final output, determine the **Top 3 Priorities** for today.

### Top 3 Priorities Logic

Weigh these factors in order of importance when selecting the top 3:

1. Overdue tasks with high importance
2. Emails from strategic senders marked urgent or high importance
3. Meetings with external attendees happening in the next 2 hours
4. Meetings with no agenda that need preparation
5. Back-to-back meeting stretches needing buffer planning
6. Emails with financial keywords (invoice, budget, grant, contract, payment)
7. Tasks due today

If fewer than 3 items warrant priority status, list only what is genuinely important. Do not pad with low-priority items. For each priority, briefly explain WHY it is a priority.

---

## Step 5: Display the Morning Briefing

Output the briefing in this format:

```
============================================================
  DAILY MORNING BRIEFING
  Julio Garcia — Executive Director, PACO Agency
  [Today's full date, e.g., Wednesday, April 16, 2026]
  Generated at [current time in EDT]
============================================================

ONENOTE STATUS
  [Will be updated after Step 6]

------------------------------------------------------------

TODAY'S SCHEDULE ([count] events)

  [For each event, chronologically:]
  [time range in EDT] — [event title]
    Location: [Online/In-Person] [location if any]
    Attendees: [count] ([external count] external)
    Flags: [any flags: back-to-back, no agenda, etc.]

  [If no events: "No meetings scheduled today."]

  Schedule Alerts:
  - [back-to-back warnings]
  - [meetings with external attendees]
  - [meetings with no agenda]

------------------------------------------------------------

INBOX SNAPSHOT
  Unread: [count] | Flagged: [count] | From Strategic Senders: [count]

  Priority Emails:
  [For each flagged email, sorted by importance:]
    [sender] — [subject]
      Flags: [high importance] [strategic sender] [attachment] [keywords]

  [If no flagged emails: "No priority emails requiring attention."]

------------------------------------------------------------

TASKS
  [If tasks available:]
  Overdue: [count] | Due Today: [count] | High Priority: [count]

  [For each flagged task:]
    [task title] — Due: [date] [flags]

  [If task API failed:]
  Task data unavailable — API returning 400 error.
  Manual check recommended at https://to-do.office.com

------------------------------------------------------------

TOP 3 PRIORITIES FOR TODAY

  1. [Most critical item — brief explanation of why]

  2. [Second priority — brief explanation]

  3. [Third priority — brief explanation]

============================================================
  End of Morning Briefing
============================================================
```

---

## Step 6: Push to OneNote

After displaying the briefing, push the complete content to OneNote.

### Cloud Mode (Primary)

Use the available OneNote MCP tools or Microsoft Graph API tools to create a new page:

- **Target notebook section:** Executive Working
- **Page title:** `[YYYY-MM-DD] — Morning Briefing`
- **Page content:** The full briefing output from Step 5, formatted as HTML for OneNote

If the page is created successfully, update the ONENOTE STATUS line in the displayed output:
```
ONENOTE STATUS: Page created successfully. [page ID or link if available]
```

If OneNote tools are not available or the call fails, report:
```
ONENOTE STATUS: FAILED — [error description]. Briefing displayed above but not saved to OneNote.
```

### Local Fallback (Windows environments only)

If running on a local Windows machine with Node.js available:

```
cd "C:\Users\user8\iCloudDrive\Documents\Work AI Hub\onenote-automation"
node createMorningBriefing.js
```

**If auth fails** (look for "auth", "token", "401", "unauthorized", "expired"):
1. Run: `node createMorningBriefing.js --auth`
2. Follow the device code flow instructions
3. Retry the original command once
4. If still failing: report `ONENOTE STATUS: FAILED — Auth re-flow did not resolve.`

**If non-auth failure:**
1. Check logs at `C:\Users\user8\iCloudDrive\Documents\Work AI Hub\onenote-automation\logs\`
2. Report: `ONENOTE STATUS: FAILED — [error from logs].`

---

## Error Recovery

If ALL steps fail (calendar, email, tasks, and OneNote), output:

```
============================================================
  DAILY MORNING BRIEFING — ERROR STATE
  [date and time]
============================================================

All data sources encountered errors:
- Calendar: [error]
- Email: [error]
- Tasks: [error]
- OneNote: [error]

Recommended actions:
1. Check that the ms-outlook-todo MCP server is connected
2. Verify Microsoft account authentication is active
3. Restart the MCP server if needed
4. Try running the briefing again
============================================================
```

---

## Strategic Senders Reference

These are key contacts whose emails should always be surfaced:

| Name | Role Context |
|---|---|
| Melissa | Internal leadership |
| Vishnu | Internal leadership |
| Ron | Internal leadership |
| Rebecca | Internal leadership |
| Israel | Internal leadership |
| Christine | Internal leadership |
| Arely Hernandez | External partner |
| Gladys Negron | External partner |

This list should be reviewed periodically with Julio for additions or changes.
