# AI_07 — Docs Authority and Usage

Which document owns which topic. When two docs disagree, the "owner" wins.

---

## Source-of-Truth Map

| Topic | Owner | Notes |
|-------|-------|-------|
| Agent behavioral rules | `CLAUDE.md` | Skills index, bug response process, critical rules |
| Tech stack & quick gotchas | `.github/copilot-instructions.md` | Copilot's primary input |
| Detailed gotchas & debug | `.claude/skills/debug/SKILL.md` | Long-form; one-liners mirrored in copilot-instructions |
| Code patterns | `.claude/skills/patterns/SKILL.md` | |
| Testing rules | `.claude/skills/testing/SKILL.md` | |
| Deploy / commit format | `.claude/skills/deploy/SKILL.md` | |
| Performance | `.claude/skills/performance/SKILL.md` | |
| Phase planning | `.claude/skills/phase-plan/SKILL.md` | |
| Phase wrap | `.claude/skills/phase-wrap/SKILL.md` | |
| Doc review | `.claude/skills/check-docs/SKILL.md` | |
| App overview | `docs/ai-context/AI_00_APP_OVERVIEW.md` | High-level context |
| Scope / non-goals | `docs/ai-context/AI_01_SCOPE_AND_NON_GOALS.md` | |
| Decisions & rationale | `docs/ai-context/AI_02_DECISIONS_AND_RATIONALE.md` | Append-only log |
| Roles & permissions | `docs/ai-context/AI_03_USER_ROLES_AND_PERMISSIONS.md` | |
| User journeys | `docs/ai-context/AI_04_USER_JOURNEYS_AND_FLOWS.md` | |
| Glossary | `docs/ai-context/AI_05_LANGUAGE_AND_GLOSSARY.md` | All terms defined here |
| Phase status | `docs/ai-context/AI_06_CURRENT_STATE_VS_FUTURE_STATE.md` | |
| File manifest (this) | `docs/ai-context/AI_07_DOCS_AUTHORITY_AND_USAGE.md` | |
| Design system | `docs/development/DESIGN-GUIDELINES.md` | |
| Voice & tone | `docs/development/LANGUAGE_STYLE_GUIDE.md` | |
| Backlog | `docs/BACKLOG.md` | |
| Changelog | `docs/CHANGELOG.md` | |
| Phase process | `docs/PHASE_PROCESS.md` | |
| Phase specs | `docs/planning/phases/PHASE_N_X_TITLE.md` | One per phase |

## Duplication Anti-Pattern

If you're tempted to repeat content across files, instead:
1. Pick the owner from the table above
2. Have other files **link** to the owner instead of restating
3. The exception: copilot-instructions intentionally mirrors short gotchas because Copilot doesn't traverse skill files

## When to Add a New Doc

- A topic is being asked about repeatedly with no canonical answer
- An existing doc has grown past ~400 lines and needs splitting
- A new long-lived process emerges (add a skill, not a free-floating doc)

## When to Delete a Doc

1. Confirm nothing links to it (`rg "filename"` across the repo)
2. Move any unique knowledge to its proper owner
3. Delete the file
4. Update this manifest
