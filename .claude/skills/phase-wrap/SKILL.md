---
name: phase-wrap
description: Phase completion, documentation updates, and wrap process for Cap & Gown. Use when wrapping or completing any phase.
disable-model-invocation: false
---

# Phase Wrap Process

## 7-Step Wrap (Do ALL of these)

### Step 1: Verify Completeness
- Review the phase spec checkboxes — are all deliverables done?
- Run `bin/rails test` — 0 failures, 0 errors
- Check for any orphaned files (created but not integrated)
- Check for any `[TODO]` markers that need resolution

### Step 2: Update ALL Documentation (CRITICAL — Most Commonly Skipped)

**This is the step that gets rushed. Don't rush it.**

Walk through each document and ask: "Did this phase's work affect this?"

- [ ] **CHANGELOG.md** — Add entries under `[Unreleased]`
- [ ] **Phase spec** — Update checkboxes, "What Was Implemented," add "Spec Deviations" if any
- [ ] **Phase status tracker** (`docs/ai-context/AI_06`) — Update phase status
- [ ] **BACKLOG.md** (`docs/BACKLOG.md`) — Items completed, new items discovered
- [ ] **AI Context Bundle** (`docs/ai-context/`) — State changes, new patterns
- [ ] **Design Guidelines** (`docs/development/DESIGN-GUIDELINES.md`) — New UI patterns established
- [ ] **Language Style Guide** (`docs/development/LANGUAGE_STYLE_GUIDE.md`) — New copy patterns
- [ ] **README.md** — Architecture changes, new setup steps

### Step 3: Reflect & Capture Learnings

Ask these questions:
1. What went well in this phase?
2. What was harder than expected?
3. Were there any gotchas or bugs worth documenting?
4. Did any patterns emerge that should be captured?

**Route learnings to the right place:**

| Learning Type | Route To |
|--------------|----------|
| Bug/gotcha | `/debug` skill + `copilot-instructions.md` Common Gotchas |
| New code pattern | `/patterns` skill |
| Behavioral rule | `CLAUDE.md` Critical Rules |
| Performance insight | `/performance` skill |

### Step 4: Create Supporting Documentation

If this phase introduced a significant feature, document it (e.g., `docs/features/FEATURE_NAME.md`). Include: what it does, how it works, key decisions, known limitations.

### Step 5: Code Review & Commit

- Review all changed files
- Commit with proper format (invoke `/deploy` skill)
- Push to main

### Step 6: Ask About Outstanding Items

Ask the user:
- "Are there any items from this phase you want to defer to backlog?"
- "Did anything come up during the phase that should be tracked?"
- Update `docs/BACKLOG.md` with any new items

### Step 7: Recommend Next Steps

- What's the next phase?
- Are there any blockers for next phase?
- Any prep work needed before starting?

## Stop-Point Handoff

When stopping work (end of session, switching tasks), always leave a clean handoff:

```markdown
## Where I Stopped
- **Last completed:** [what was just finished]
- **Next up:** [what should be done next]
- **Blockers:** [anything preventing progress]
- **Notes:** [context the next session needs]
```
