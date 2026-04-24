# Phase Process

How phases are planned, executed, and wrapped in Cap & Gown.

Companion skills: `/phase-plan` (planning), `/phase-wrap` (completion).

---

## Phase Numbering

- **Major phases** are integers: `Phase 1`, `Phase 2`, `Phase 3`.
- **Sub-phases** are decimals: `Phase 1.1`, `Phase 1.2`.
- No letter suffixes (`1A`, `1B`) — always numbers.

The authoritative status of every phase lives in [`docs/ai-context/AI_06_CURRENT_STATE_VS_FUTURE_STATE.md`](ai-context/AI_06_CURRENT_STATE_VS_FUTURE_STATE.md).

## Phase Lifecycle

```
PLANNING → IN PROGRESS → WRAP → DONE
```

### Planning
Use the `/phase-plan` skill. Required outputs:
- A spec file at `docs/planning/phases/PHASE_N_X_TITLE.md`
- Open questions answered or explicitly deferred
- User confirmation before any code is written

### In Progress
- Update the spec's "What Was Implemented" bullets as you go (not at the end)
- Update `CHANGELOG.md` under `[Unreleased]` as features land
- Add tests AS code is written, not after
- Add any new gotchas to `/debug` skill + `copilot-instructions.md` Common Gotchas

### Wrap
Use the `/phase-wrap` skill. The 7-step wrap is mandatory; the documentation step is the most commonly skipped — don't.

## Spec File Location

```
docs/planning/phases/
  PHASE_1_FOUNDATIONS.md
  PHASE_1_1_BASELINE_TESTS.md
  PHASE_2_AUTH.md
  ...
```

Use the template in the `/phase-plan` skill.

## Spec Deviations

If implementation must differ from the spec:
1. **Stop**, don't silently build something else
2. Explain the deviation
3. Get explicit user approval
4. Update the spec with a "Spec Deviation" note immediately
