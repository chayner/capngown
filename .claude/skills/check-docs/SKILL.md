---
name: check-docs
description: Review and consolidate Cap & Gown documentation. Use when user says "check docs" or "review documentation".
disable-model-invocation: false
---

# Check Docs — Documentation Review Procedure

**Trigger:** "check docs", "review documentation", or when docs feel out of sync.

## Step-by-Step Review

### 1. Scan for Broken References
```bash
# Find all markdown links and check if targets exist
rg '\[.*?\]\(((?!http)[^)]+)\)' docs/ --only-matching -r '$1' | while read link; do
  [ ! -f "$link" ] && echo "BROKEN: $link"
done
```

### 2. Check for Duplication
Look for the same information in multiple files. Common culprits:
- Stack description (`CLAUDE.md` vs `AI_00` vs `README.md`)
- Role definitions (`CLAUDE.md` vs `AI_03` vs `copilot-instructions.md`)
- Gotchas (`debug` skill vs `copilot-instructions.md` Common Gotchas)

**When you find duplication:** One file is the source of truth; all others reference it. See the table below.

### 3. Verify Single Source of Truth

| Topic | Source of Truth |
|-------|----------------|
| Agent behavioral rules | `CLAUDE.md` |
| Tech stack & conventions | `.github/copilot-instructions.md` |
| Phase status | `docs/ai-context/AI_06_CURRENT_STATE_VS_FUTURE_STATE.md` |
| Role permissions | `docs/ai-context/AI_03_USER_ROLES_AND_PERMISSIONS.md` |
| Terminology & glossary | `docs/ai-context/AI_05_LANGUAGE_AND_GLOSSARY.md` |
| Visual design system | `docs/development/DESIGN-GUIDELINES.md` |
| Voice & tone | `docs/development/LANGUAGE_STYLE_GUIDE.md` |
| Feature backlog | `docs/BACKLOG.md` |
| Changelog | `docs/CHANGELOG.md` |
| Detailed gotchas | `.claude/skills/debug/SKILL.md` (one-liners mirrored in `copilot-instructions.md`) |

### 4. Update the README Index
Verify that `README.md` lists all docs that exist and doesn't reference any that don't.

### 5. Audit CHANGELOG
- Is there an `[Unreleased]` section?
- Does it reflect recent work?
- Are entries in reverse chronological order?

### 6. Review BACKLOG
- Are any items completed but still listed?
- Are there new items from recent work that should be tracked?

### 7. Fix Broken References
For each broken link:
- If the file was moved, update the link
- If the file was deleted, remove the reference
- If the file should exist but doesn't, flag it

### 8. Look for Consolidation Opportunities
- Multiple small docs that should be one
- A doc that's grown too large and should be split
- Docs with overlapping scope that should be merged

## Before Deleting Any Doc

1. Check if anything links to it
2. Extract any unique knowledge to the appropriate surviving doc
3. Update `AI_07` file manifest
4. Update any README doc tables
