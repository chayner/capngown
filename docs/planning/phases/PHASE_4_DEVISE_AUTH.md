# Phase 4 — Devise Auth (Admin + Volunteer)

**Status:** In Progress
**Started:** 2026-04-24
**Completed:** _(not yet)_

## Goal
Add Devise authentication and a two-role hierarchy (`Admin`, `Volunteer`) so the app is no longer publicly reachable.

## Context
The app is currently open. The original spec called for a 3-role hierarchy (Volunteer / Coordinator / Admin). After re-scoping with the user, **only two roles are needed**:
- **Admin** — user management + file imports (handled by Phase 5)
- **Volunteer** — everything else (look up, check in, mark printed, view stats, bulk operations)

## Sub-Phase Split

Phase 4 is split into three sub-phases so we can land the auth work safely on top of the (currently empty) test suite:

- **Phase 4.1** — Baseline test coverage for existing controllers/models
- **Phase 4.2** — Devise install + `User` model + role enum
- **Phase 4.3** — Apply `authenticate_user!` site-wide + sign-in UI + first-admin bootstrap + admin password-reset path

## Decisions (resolved 2026-04-24)

| Question | Decision |
|----------|----------|
| Self-signup vs invite-only | **Invite-only.** Admins create volunteer accounts. |
| First-admin bootstrap | **Rake task** (`rails admin:create EMAIL=... PASSWORD=...`). Document the `heroku run` invocation. |
| Password reset email | **Deferred to backlog.** Admin must have a manual way to reset a user's password (rake task `admin:reset_password EMAIL=... PASSWORD=...`). |
| Sessions | **Standard Devise** (per-browser cookie). |
| Password complexity | **Length only — minimum 8 chars.** No symbol requirements. |

## Scope

**In:**
- Add `devise` gem
- Generate `User` model with `role` enum (`admin`, `volunteer`), default `volunteer`
- Sign-in / sign-out flows (no public sign-up)
- `before_action :authenticate_user!` on every controller (except Devise sign-in pages)
- Helper methods: `current_user.admin?`, `current_user.volunteer?` (admin returns true for both)
- Rake tasks: `admin:create`, `admin:reset_password`
- Update layout: show signed-in user + sign-out link in nav
- Tests: model + controller authorization tests
- Min password length 8

**Out (deferred):**
- Admin UI for managing users → Phase 5
- File import UI → Phase 5
- OAuth / SSO
- Password reset emails → BACKLOG
- 2FA
- Coordinator role
- Audit log → BACKLOG

## Pre-Flight Checks

- [x] Phase 2 + 3 complete
- [ ] Baseline test coverage exists for existing actions (Phase 4.1)
- [x] User decided: invite-only

## Deliverables

### Phase 4.1 — Baseline tests
- [x] Fix broken fixtures (`students.yml` → `graduates.yml`, fix `cords.yml` column name)
- [x] Smoke tests for every public action in `GraduatesController`
- [x] Smoke test for `PagesController#home`
- [x] Basic model tests (`Graduate`, `Brag`, `Cord` associations + sanity)
- [x] All tests green (28 runs, 64 assertions, 0 failures)

### Phase 4.2 — Devise install
- [ ] `devise` added to Gemfile, `bundle install`
- [ ] `bin/rails g devise:install`
- [ ] Devise initializer configured (mailer sender, min password length 8)
- [ ] `User` model with email + encrypted_password + role enum
- [ ] Migration: `users` table with `role` integer column, default 0 (volunteer)
- [ ] `User#admin?` returns true for admins; `User#volunteer?` returns true for both admins and volunteers (hierarchy)
- [ ] User model tests
- [ ] Disable public registration (`devise_for :users, skip: [:registrations]`)

### Phase 4.3 — Apply auth + UI + bootstrap
- [ ] `ApplicationController#before_action :authenticate_user!`
- [ ] `before_action :require_admin!` helper available
- [ ] Sign-in view styled with Picnic CSS
- [ ] Nav shows current user email + sign-out link
- [ ] Rake task: `admin:create EMAIL=... PASSWORD=...`
- [ ] Rake task: `admin:reset_password EMAIL=... PASSWORD=...`
- [ ] Documented Heroku invocation in `docs/development/`
- [ ] Tests: redirect-when-not-signed-in for every controller; `require_admin!` rejects volunteers
- [ ] CHANGELOG updated
- [ ] AI_03 (roles) updated to reflect 2-role reality
- [ ] `CLAUDE.md` + `.github/copilot-instructions.md` updated to drop "future state" wording around auth

## Acceptance Criteria

- [ ] Visiting any page when signed out redirects to sign-in
- [ ] Volunteer can do all check-in/print/stats operations
- [ ] Admin can do everything Volunteer can do
- [ ] Admin-only routes reject volunteers with 403 / redirect (placeholder route fine for testing)
- [ ] Sign-in works on mobile (volunteers will use phones/tablets)
- [ ] All tests pass

## What Was Implemented

### Phase 4.1 (complete)
- Removed orphan/broken fixtures (`students.yml` deleted; `cords.yml`, `brags.yml` rewritten; `graduates.yml` created).
- 26 controller tests across `GraduatesController` covering all routed actions + 2 in `PagesController`.
- Model tests for `Graduate`, `Brag`, `Cord`.
- Fixed: `config.hosts << "15ltws037665pmo.local"` was in `config/application.rb`, activating host authorization in test env (every request was 403). Moved to `config/environments/development.rb`.
- Test suite: **28 runs, 64 assertions, 0 failures**.

## Spec Deviations
_(Add immediately when implementation differs.)_

## Notes
- Update `CLAUDE.md`, `.github/copilot-instructions.md`, and `AI_03` to reflect 2-role hierarchy when this phase wraps.
- Consider a "kiosk mode" later if shared devices become painful.
- Password reset by email is deliberately deferred — `admin:reset_password` rake task is the manual path until then.
