# AI_04 — User Journeys and Flows

## Journey 1: Check-In a Graduate

**Actor:** Volunteer at the distribution table.

1. Navigate to `/start`.
2. Search by BUID (preferred) or name.
3. App shows matching graduate(s).
4. Volunteer confirms identity (visual check against student ID).
5. Click "Check In" → `PATCH /graduates/:buid/checkin` sets `checked_in = Time.now`.
6. Optional: enter height (used to pick gown size).
7. Graduate flows into the print queue (`printed IS NULL AND checked_in IS NOT NULL`).

**Failure modes:**
- Graduate not in the roster → escalate to coordinator (no self-service add).
- Wrong graduate checked in → re-open record, hit `?checkin=clear` to undo.

## Journey 2: Print Sticker(s)

**Actor:** Volunteer at the print station.

1. Navigate to `/print` (the to-print queue).
2. Page shows all checked-in-but-not-printed graduates.
3. Auto-rendered print partial (`get_print_html`) feeds the sticker printer.
4. After print, mark the graduate(s) `printed`.

**Bulk variant:**
- Select multiple BUIDs, navigate to `/show_bulk?buids=B0001,B0002,...`.
- Click bulk print → all marked at once.
- "Clear printed" available via `?print=clear`.

## Journey 3: Stats Dashboard

**Actor:** Coordinator monitoring distribution progress.

1. Navigate to `/graduates/stats`.
2. See totals + percentages by level (UG / GR-M / GR-D), by college (with program breakdown), by brag pickup, by cord pickup.
3. Refresh periodically during distribution.

## Journey 4: Re-open / Undo

**Actor:** Coordinator fixing a mistake.

1. Look up the graduate.
2. Append `?checkin=clear` or `?print=clear` to the relevant action.
3. State flag is set back to `nil`.

---

## Journey Health Checks

When you build new features, walk through each journey to make sure nothing breaks:
- Can a volunteer still find a graduate by BUID?
- Does the print queue still update after check-in?
- Does the stats dashboard still load?
