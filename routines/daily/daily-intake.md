# Daily Intake — Julio's Daily Operating System

> **Schedule:** Daily at 7:20 AM
> **Trigger:** Automated / On-demand
> **System:** Obsidian (2nd Brain) — Thinking Layer

This skill creates or updates Julio's daily note in his Obsidian vault, populated with real context from his calendar, projects, and personal goals. The standalone template in Obsidian works as a self-guided questionnaire; this skill's job is to pre-fill it with live data so Julio starts his day with context already loaded rather than a blank page.

## Integration with OneNote Morning Briefing

Julio runs a two-hub system. Understanding the relationship prevents duplication and makes both systems stronger:

| Hub | System | Generated | Contains | Purpose |
|-----|--------|-----------|----------|---------|
| **Operational** | OneNote (Executive Working) | Auto at 6 AM via `createMorningBriefing.js` | Outlook calendar, email triage (Hard Rule / Strategic / Operational / Informational), standing priorities, rollovers, sent mail analysis | What's happening today — meetings, emails, fires |
| **Thinking** | Obsidian (2nd Brain) | On-demand via this skill | Calendar (Google + Outlook), carry-overs from previous days, active project context, reflections, golf/fitness, Daily Intel synthesis | What matters today — priorities, patterns, decisions |

**The flow:** The OneNote briefing runs first (6 AM, no input needed). When Julio sits down and runs daily intake, this skill pulls from the same calendar sources *and* cross-references the briefing's email triage. The Obsidian daily note becomes the thinking layer on top of the operational data.

**Key principle:** OneNote answers "what landed in my inbox and calendar?" — Obsidian answers "what should I actually focus on and why?" They complement, not compete.

## Vault Layout

**Vault root:** `/Users/juliogarcia/Library/Mobile Documents/iCloud~md~obsidian/Documents/Julio 2nd Brain/`

All paths below are relative to the vault root. **Use direct filesystem tools (Read, Write, Edit, Glob, Grep) with the full absolute iCloud path for all vault operations.** Obsidian watches the vault folder and picks up changes automatically — no MCP server needed.

| Path | What lives here |
|------|----------------|
| `50-Daily/YYYY-MM-DD.md` | Daily notes |
| `30-Resources/Templates/Daily Note.md` | The template (numbered sections 1-8 with `[!question]` callouts) |
| `10-Projects/` | Active projects with outcomes and deadlines |
| `20-Areas/` | Ongoing responsibilities (e.g., PACO Grant Portfolio) |
| `70-Personal/Golf Game Overview — Arccos Stats.md` | Arccos strokes-gained data |
| `70-Personal/Workouts/` | Fitness logs |
| `Claude – Operating Manual.md` | Vault rules — follow its frontmatter, linking, and filing conventions |

## Execution Flow

### Step 1: Check if today's note exists

Use the **Read** tool to read `{VAULT_ROOT}/50-Daily/YYYY-MM-DD.md` (today's date, full absolute path).

- **Exists:** You're updating — read it, skip to Step 3. Do not overwrite anything already written.
- **Doesn't exist:** Proceed to Step 2.

### Step 2: Create today's note from template

Use the **Read** tool to read `{VAULT_ROOT}/30-Resources/Templates/Daily Note.md`. Replace template variables:

| Variable | Replacement | Example |
|----------|------------|---------|
| `{{date:YYYY-MM-DD}}` | Today's ISO date | `2026-03-16` |
| `{{date:dddd, MMMM D, YYYY}}` | Full formatted date | `Monday, March 16, 2026` |
| `{{date:HH:mm}}` | Current time | `08:30` |

Use Bash with heredoc (`cat > "path" << 'EOF'`) to save the populated template to `{VAULT_ROOT}/50-Daily/YYYY-MM-DD.md`. The Write tool requires a prior Read on the same path, which fails for new files — always use Bash for creation. Obsidian will detect the new file automatically.

### Step 3: Gather context

Pull data from multiple sources. Launch these in parallel where possible — they're independent of each other.

#### 3a. Today's calendar

Use `reclaim_list_events` with start_date and end_date set to today. Also use `outlook_calendar_search` with afterDateTime/beforeDateTime for today.

- **If events found:** Format into a schedule table.
- **If no events:** Note it as a clear day — that's useful context too ("No meetings — protect this for deep work").

#### 3b. Carry-over detection

Use the **Glob** tool with pattern `*.md` in `{VAULT_ROOT}/50-Daily/` to list daily notes (they're date-sorted: `YYYY-MM-DD.md`). Read the last 2-3 notes using the **Read** tool.

Scan for:
- **Unchecked items** — `- [ ]` lines in sections 1 (Morning Check-In) and 6 (Action Items)
- **Carry-over declarations** — anything in section 8 (End of Day Review) under "What am I carrying over to tomorrow?"
- **Repeat offenders** — items appearing unchecked across multiple days. These are avoidance signals worth calling out.

#### 3c. Active projects

Use the **Glob** tool on `{VAULT_ROOT}/10-Projects/` to list project files. Read the 3-5 most relevant using the **Read** tool — prioritize those with upcoming deadlines or recent modifications.

Extract: open TODOs, next steps, deadlines, items needing ED attention.

#### 3d. Golf & fitness

Read `70-Personal/Golf Game Overview — Arccos Stats.md` — specifically the "Latest Round" and "Top 3 Insights" sections.

Read `70-Personal/Workouts/Workouts.md` and any recent files in `70-Personal/Workouts/` for the last logged session.

**IMPORTANT — Workout detection from previous daily notes:** The Workouts.md index may be empty. The primary source for recent workout data is the **previous daily notes themselves**. When scanning the last 2-3 daily notes in Step 3b, also extract workout data from the `Gym / Fitness` section:
- Look for checked workout checkboxes: `- [x] Workout`
- Extract: date, type, focus area, instructor, and any notes
- Use this to populate the "Last workout" line in today's note
- This prevents the note from saying "no workout logged" when one was clearly recorded yesterday

#### 3e. Morning Briefing cross-reference

The OneNote morning briefing runs at 6 AM via `createMorningBriefing.js` in `/Users/juliogarcia/Documents/AI Data Hub/onenote-automation/`. It pulls Outlook calendar events and email from the last 24 hours, classifying messages into four tiers:

| Tier | What it catches | Action level |
|------|----------------|--------------|
| **Hard Rule** | VBII/IRS, lender control, NJHMFA, life-safety, board quorum, audit findings, legal notices | Flag immediately — do not act without ED review |
| **Strategic** | Emails from key people (Melissa, Vishnu, Ron, Rebecca, Israel, Christine, Arely, Gladys, Eddie/JMax) | Review and respond today |
| **Operational** | Invoices, payroll, timecards, Suralink, reminders | Process during admin blocks |
| **Informational** | Everything else | Scan and file |

To cross-reference, use Outlook email search (`outlook_email_search`) with afterDateTime/beforeDateTime for today to check for any Hard Rule or Strategic emails from today. You don't need to re-read the full OneNote page — the briefing data comes from the same Outlook source, so checking email directly gives you the same picture.

**What to extract for the daily note:**
- Count of Hard Rule triggers (if any — these are the fires)
- Names of Strategic senders who emailed (so Julio knows who to respond to)
- Any email subjects that overlap with active projects in `10-Projects/` (connect the dots)

**What NOT to do:**
- Don't duplicate the full email triage into Obsidian — that lives in OneNote
- Don't list every operational/informational email — noise, not signal
- Do flag if the briefing appears to have NOT run (no recent briefing page) so Julio knows to run it manually

### Step 4: Populate the daily note

Use Bash with heredoc for new files, or the **Edit** tool for updating existing notes. Insert content into the correct sections of the daily note file (full absolute path). The template uses these headings:

| Template Section | Heading to Target | What to Insert |
|-----------------|-------------------|----------------|
| Daily Intel | `[!info] Daily Intel` | 5-7 punchy bullets: briefing status, fires, deadlines, key meetings, fitness/golf one-liner |
| Top 3 | `Top 3 Today` | The 3 most important things + "Avoiding" line (repeat offenders from carry-over scan) |
| Schedule | `Schedule` | Calendar table — real meetings + task blocks |
| Brain Dump | `Brain Dump` | Leave empty — this is Julio's space. Include the tag reference block (`#idea`, `#thought`, `#question`, `#research-me`, `#research-for-work`). Never pre-fill. |
| PACO Work Focus | `Grants & Funding`, `Board & Governance`, `Programs & Operations` | Active items with `[[wiki links]]`. 🔴 for today, 🟠 for this week. No instructional callouts. |
| Personal | `Personal` | Checkboxes: Workout / Rest day / Golf. One-liner each: last workout date, next lesson/round. Family items. |
| Pets | `Pets` (under Personal) | Per-pet table (Adele/Biggie/Cardi) with meds, food, notes columns. Next vet date. Daily checkboxes: meds given, food order needed. |
| Action Items | `Action Items` | Single table: What / Due / Priority. Cap at ~15 rows. |
| Backlog | Collapsed `[!warning]` block under Action Items | Items older than 7 days that aren't due today. One line each. Keeps them visible without cluttering the action list. |

**Daily Intel callout** — first bullet always references OneNote morning briefing status. Be direct. Example:
```
> [!info] Daily Intel
> - 🔴 ADP x3 overdue (4-6 days). Clear before 8 AM.
> - 🔴 [[Nuestra Historia]] meeting TODAY 11 AM — bring HPP agreement.
> - ⚠️ VB2 audit deadline in 2 days. Name the doc owner.
> - ⛳ Sam Kang lesson Wed. 4 days no workout — hip mobility tonight.
```

**Carry-overs — max 5-7 in the Top 3 / Action Items.** Everything else goes to Backlog. A 20-item carry-over list is a task manager, not a daily note.

**Personal section — weekday vs. weekend:**

**Monday–Thursday (no golf detail):**
```
- [ ] Workout →
- [ ] Rest day
- **Last workout:** [[2026-04-09]] — Push-Pull @ TBT. 4 days ago.
- **Next round/lesson:** Sam Kang, Wed Apr 15.
```

**Friday–Sunday (full golf section):** On Fri/Sat/Sun, expand the golf section with the full intake — last round recap, weakness table from [[Golf Game Overview — Arccos Stats]], practice suggestions, drill prompts, and round logging fields:
```
- [ ] Workout →
- [ ] Rest day
- [ ] Round
- [ ] Range
- [ ] Short game
- [ ] No golf today
- **Last workout:** [[2026-04-09]] — Push-Pull @ TBT. 4 days ago.

**Last round:** Seaview Pine, 104. Approach -12.4 SG. Short game strong.
**Today's focus:** If practicing, hit 20 balls with 7i (144 yds) — ball-first contact.

| Priority | Weakness | SG Loss | What to Do |
|----------|----------|---------|------------|
| 1 | Approach from fairway | -3.1 | Ball-first contact. Left hand firm. |
| 2 | Driving distance | -3.1 | Rotation and lag. |
| 3 | Approach from rough | -2.4 | One more club. |

**If playing:**
- **Course:**
- **Score:**
- **What went well:**
- **What cost me strokes:**
```
No weakness tables or drill fields on weekdays — that detail only matters when golf is likely.

**Pets section — always included (every day):**
```
### Pets

| Pet | Meds | Food | Notes |
|-----|------|------|-------|
| 🐶 Adele (Bulldog) |  |  |  |
| 🐱 Biggie |  |  |  |
| 🐱 Cardi |  |  |  |

- **Next vet:**
- [ ] Meds given today
- [ ] Food order needed
```

Populate from carry-over scan:
- If a previous daily note mentions a vet appointment, surface it in "Next vet."
- If a previous note flagged "food order needed" unchecked, carry it forward into today's Notes column.
- If meds were logged in a previous note, pre-fill the Meds column with the med name so Julio just checks the box.

**Tone:** Direct and honest. Clear signals about what matters today and what's slipping. If something is a repeat offender, name it in the "Avoiding" line, not in a 20-item carry-over block.

### Step 5: Done — no conversational summary

After the note is written, output nothing to the user. The note is in Obsidian — Julio reads it there. Silence is the correct output.

## Time-of-Day Awareness

| Time | Mode | Focus |
|------|------|-------|
| Before noon | Morning intake | Full build: calendar, carry-overs, intentions, practice prompts. Forward-looking energy. |
| Noon–5 PM | Midday check-in | What's done, what's left, any surprises. Update the work log and action items. |
| After 5 PM | Evening reflection | Prompt the End of Day Review. Surface wins. Identify carry-overs for tomorrow. |

### Evening Mode — What to Do Differently

When running after 5 PM, the skill shifts from forward-looking to reflective. The key differences:

1. **Do NOT recreate morning sections** — the daily note already exists. Read it, don't rebuild it.
2. **Prompt the 5 EOD questions explicitly.** Don't just summarize the day — ask Julio to answer these, one by one:
   - "Did I move the needle on my #1 priority?"
   - "What surprised me today?"
   - "What am I carrying over to tomorrow?"
   - "Is there a decision I've been avoiding?"
   - "Did anything come up that deserves its own note?"
3. **Patch the End of Day Review section** with what you know — pre-fill carry-over items, flag decisions being avoided, note wins if any were logged. Leave the subjective questions (surprises, feelings) for Julio to answer.
4. **Surface wins.** Check the Wins & Gratitude section — if it's empty, gently prompt: "You didn't log any wins today. Even small ones count. What went right?"
5. **Build tomorrow's priority stack** based on what didn't get done + what's upcoming on the calendar.

### Carryover-Only Mode

When Julio asks specifically about carry-overs ("what carried over?", "what did I forget?"), the skill should:

1. Read the last 2-3 daily notes and scan for unchecked `- [ ]` items
2. **Always update today's daily note** with a carry-over block in Section 1 (Morning Check-In) using the **Edit** tool on the full absolute file path. Don't just report — edit the note so the items are visible in Obsidian.
3. Identify repeat offenders across multiple days and name the pattern (e.g., "3 of 5 carry-overs are phone calls — that's avoidance, not forgetting")
4. Give specific, time-boxed advice: "Block 15 minutes before lunch and make all 3 calls back-to-back"

## Key Rules

- **Frontmatter:** `context: mixed`, `type: daily` for all daily notes
- **Never overwrite** existing content — only append or patch into sections
- **Use direct filesystem tools** (Read, Write, Edit, Glob, Grep) with absolute paths under the vault root for all vault operations. Obsidian watches the folder and picks up changes automatically — no MCP server needed.
- **For new file creation:** Always use Bash with heredoc (`cat > "path" << 'EOF'`). The Write tool requires a prior successful Read on the same path, which fails for files that don't exist yet.
- **Link generously** — every project, area, entity, or person should be a `[[wiki link]]` if a note exists
- **Timestamps** — `**[HH:MM]**` format for thoughts
- **Standing permission** to create daily notes in `50-Daily/` without asking — the Operating Manual's "ask before creating" rule is waived for this skill

## Golf Reference (Arccos Data)

The template already includes the full weakness table. When generating practice suggestions, use these details to be specific:

**Current weaknesses (SG/round vs 18 HCP):**
1. Approach from fairway: -3.1 SG → Ball-first contact, consistent divots
2. Driving distance: -3.1 SG → Rotation and lag
3. Approach from rough: -2.4 SG → Lie assessment, club selection
4. Driving accuracy: -2.4 SG → 28% fairways, miss left
5. 100-150 yd approach: -2.3 SG → Tempo over power

**Strength:** Putting +4.6 SG (10-25 ft range is +2.7 SG alone). Remind him to maintain this.

**Club distances:** Driver 225, 4H 180, 6H 167, 6i 158, 7i 144, 8i 139, 9i 130, PW 115, AW 103, 52° 91, 56° 75, 60° 67

Be specific in suggestions: "Hit 20 balls with your 7i from 145 yards, focusing on ball-first contact" beats "work on your irons."

## No Notion Backup

Do not back up the daily note to Notion. Obsidian is the only destination.
