---
name: phase-plan
description: Phase planning, sub-phase interviews, and launch guides for Cap & Gown. Use when starting or planning any phase/sub-phase.
disable-model-invocation: false
---

# Phase Planning

## Phase Numbering Convention

**Format: `N.X`** — No letter suffixes, no `A/B/C`.

- `Phase 1` = Major phase
- `Phase 1.1`, `1.2`, `1.3` = Sub-phases within Phase 1
- `Phase 2` = Next major phase

**Phase status source of truth:** `docs/ai-context/AI_06_CURRENT_STATE_VS_FUTURE_STATE.md`

**Phase spec files:** `docs/planning/phases/PHASE_N_X_TITLE.md`

## Sub-Phase Planning Checkpoint (MANDATORY)

**Before starting ANY sub-phase, run this 5-step checkpoint.** Do NOT begin implementation until the user confirms.

### Step 1: In-Depth Interview
Review the phase spec and ask the user:
- What are your specific goals for this sub-phase?
- Are there any changes to scope since the spec was written?
- Any lessons from the previous sub-phase that affect this one?
- What concerns you most about this sub-phase?

### Step 2: Outstanding Questions
Review the "Open Questions" section in the phase spec:
- Which questions from the spec can we answer now?
- Have new questions emerged since the spec was written?
- Are there any design decisions that need to be made before we start?

### Step 3: Scope Review
Present the scope clearly:
- What's IN this sub-phase
- What's explicitly OUT (deferred to later)
- What are the acceptance criteria

### Step 4: Backlog Review
Check `docs/BACKLOG.md`:
- Are any backlog items now ready to include?
- Should anything from this sub-phase be deferred to backlog instead?

### Step 5: Planning Summary
Present a clear summary for confirmation:
```
Sub-phase: [N.X] [Title]
Goal: [One sentence]
Key deliverables:
- [deliverable 1]
- [deliverable 2]
Open questions resolved: [list]
Deferred to later: [list]
```

**Ask: "Does this match your expectations? Ready to start?"**

## Phase Spec Template

When creating `docs/planning/phases/PHASE_N_X_TITLE.md`:

```markdown
# Phase N.X — [Title]

**Status:** Planned | In Progress | Complete
**Started:** [date]
**Completed:** [date]

## Goal
[One sentence]

## Scope
**In:**
- [Item]

**Out (deferred):**
- [Item]

## Deliverables
- [ ] [Item 1]
- [ ] [Item 2]

## Acceptance Criteria
- [ ] [Criterion]

## Open Questions
- [Question deferred from strategic planning]

## What Was Implemented
_(Filled in as work progresses; do not wait until wrap.)_

- [Item with link to commit/PR]

## Spec Deviations
_(Add immediately when implementation differs from spec.)_

## Notes
- [Decisions made during planning]
```

## Starting a Phase — Open Questions Workflow

Phase specs include an "Open Questions" section — questions deliberately deferred from strategic planning.

When a phase begins:
1. **Read the spec** — especially Open Questions and Acceptance Criteria
2. **Answer the open questions** — walk through each with the user, document answers
3. **Update the spec** — move answered questions out of "Open Questions" and into the relevant section
4. **Identify new questions** — implementation always surfaces new questions; add them
5. **Confirm scope** — make sure the phase scope still makes sense given the answers
