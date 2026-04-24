# AI_00 — App Overview

**Start here.** This file is the high-level context bundle for AI agents working on Cap & Gown. It links out to the more detailed AI_0* files.

---

## What Cap & Gown Is

Cap & Gown is a web-based app that assists in the **check-in and printing of stickers for the distribution of caps & gowns at Belmont University**. The goal is to streamline the distribution process while making it fun, easy, and meaningful for our graduates.

## Who Uses It

- **Distribution-day staff and volunteers** — look graduates up, check them in, print sticker labels for their packets.
- **Coordinators / managers** — monitor progress on the stats dashboard.
- _(Future)_ **Admin users** — import roster data, manage user accounts.

## Core Domain

| Concept | Notes |
|---------|-------|
| `Graduate` | A degree candidate. PK = `buid` (string). |
| `Brag` | An optional recognition card. Many per graduate. |
| `Cord` | An honor cord. Composite identity `[buid, cord_type]`. No `id` column. |

## Primary User Flows

1. **Check-in:** Look up graduate (BUID or name) → confirm record → mark `checked_in` → optionally capture `height`.
2. **Print queue:** Checked-in graduates appear in a print list → staff prints sticker labels → records get `printed` timestamp.
3. **Bulk print:** Multi-BUID list driven by `?buids=B0001,B0002` for batch print/clear actions.
4. **Stats:** Dashboard shows progress by college, level, brag pickup, cord pickup.

## Tech Stack (One-Liner)

Rails 7.1 / Ruby 3.2.3, PostgreSQL, Picnic CSS, Importmap + Turbo + Stimulus, deploying to Heroku. No auth today (Devise planned).

## Where to Look Next

| If you need... | Read |
|---|---|
| What's in scope vs out | [AI_01_SCOPE_AND_NON_GOALS.md](AI_01_SCOPE_AND_NON_GOALS.md) |
| Why decisions were made | [AI_02_DECISIONS_AND_RATIONALE.md](AI_02_DECISIONS_AND_RATIONALE.md) |
| Roles & permissions | [AI_03_USER_ROLES_AND_PERMISSIONS.md](AI_03_USER_ROLES_AND_PERMISSIONS.md) |
| User journeys | [AI_04_USER_JOURNEYS_AND_FLOWS.md](AI_04_USER_JOURNEYS_AND_FLOWS.md) |
| Glossary | [AI_05_LANGUAGE_AND_GLOSSARY.md](AI_05_LANGUAGE_AND_GLOSSARY.md) |
| Where we are vs where we're going | [AI_06_CURRENT_STATE_VS_FUTURE_STATE.md](AI_06_CURRENT_STATE_VS_FUTURE_STATE.md) |
| Doc authority / which file owns what | [AI_07_DOCS_AUTHORITY_AND_USAGE.md](AI_07_DOCS_AUTHORITY_AND_USAGE.md) |

## Operating Calendar

The app's busy season is around Belmont's commencement weeks. Most of the year it sits idle. Don't deploy risky changes during distribution week.
