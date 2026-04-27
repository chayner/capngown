# AI_06 — Current State vs Future State

This file is the **source of truth for phase status**. Update it as phases land.

---

## Current State (as of bringing the app up to AI-assisted standards)

### What Works Today
- Graduate lookup by BUID and name (`GraduatesController#start`, `#list`)
- Single check-in / clear check-in (`#checkin`)
- Single print / clear print (`#print`)
- Bulk show + bulk print (`#show_bulk`, `#bulk_print`)
- To-print queue (`#to_print`, `#get_print_html`)
- Stats dashboard with college / level / brag / cord breakdowns (`#stats`)
- Brag card display
- Honor cord display
- Picnic CSS layout with responsive nav
- Heroku Postgres on PG 16.13 (`postgresql-crystalline-90781`, essential-0)
- Heroku stack on `heroku-24` with runtime modernization (Ruby 3.3.10, Bundler 2.7.2, Puma 8.x, Node pinned via `engines.node`)

### What's Missing
- **Tests** — baseline + Phase 5 coverage now exists (105 runs, 298 assertions); deeper feature/edge tests still TBD
- **CI** — no GitHub Actions
- **Background jobs** — no Sidekiq
- **Audit log** — import history exists; per-record (check-in/print) audit still TBD
- **Password reset email** — admin-driven only via `admin:reset_password` rake task
- **Phase 3 follow-up** — optional Ruby patch bump to 3.3.11 and final warning-cleanup verification

---

## Phases

### Phase 0 — AI Bootstrapping
**Status:** Complete
**Goal:** Bring the app up to AI-assisted-development standards.
**Deliverables:**
- [x] `CLAUDE.md` and `.github/copilot-instructions.md`
- [x] `.claude/skills/` set
- [x] `docs/` scaffolding

### Phase 1 — Heroku Cleanup
**Status:** Complete
**Goal:** Remove Railway-era artifacts and document the live Heroku setup.
**Deliverables:**
- [x] Remove `rails_12factor` gem
- [x] Clean `config/database.yml` production block (no hardcoded credentials)
- [x] Add explicit `Procfile` with web + release commands
- [x] Update docs to reflect live Heroku state

### Phase 2 — Postgres 15 → 16 Upgrade
**Status:** Complete
See `docs/planning/phases/PHASE_2_POSTGRES_16_UPGRADE.md`.

### Phase 3 — Heroku Stack 22 → 24 Upgrade
**Status:** Complete
See `docs/planning/phases/PHASE_3_HEROKU_24_UPGRADE.md`.

### Phase 4 — Devise Auth (Admin + Volunteer)
**Status:** Complete
See `docs/planning/phases/PHASE_4_DEVISE_AUTH.md`.

### Phase 5 — Admin Interface (User Mgmt + File Imports)
**Status:** Complete
See `docs/planning/phases/PHASE_5_ADMIN_INTERFACE.md`.

---

## Future State (Direction)

A multi-user, role-aware, tested, CI'd Rails app deployed to Heroku, ready to support Belmont's commencement weeks reliably year over year. Stats and audit visibility for coordinators. Easy onboarding for new volunteers.
