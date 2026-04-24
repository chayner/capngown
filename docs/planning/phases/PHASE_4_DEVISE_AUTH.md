# Phase 4 — Devise Auth (Admin + Volunteer)

**Status:** Complete
**Started:** 2026-04-24
**Completed:** 2026-04-24

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
- [x] `devise` added to Gemfile, `bundle install`
- [x] `bin/rails g devise:install`
- [x] Devise initializer configured (mailer sender, min password length 8)
- [x] `User` model with email + encrypted_password + role enum
- [x] Migration: `users` table with `role` integer column, default 0 (volunteer)
- [x] `User#admin?` returns true for admins; `User#volunteer?` returns true for both admins and volunteers (hierarchy)
- [x] User model tests
- [x] Disable public registration (`devise_for :users, skip: [:registrations]`)

### Phase 4.3 — Apply auth + UI + bootstrap
- [x] `ApplicationController#before_action :authenticate_user!`
- [x] `before_action :require_admin!` helper available
- [x] Sign-in view styled with Picnic CSS
- [x] Nav shows current user email + sign-out link
- [x] Rake task: `admin:create EMAIL=... PASSWORD=...`
- [x] Rake task: `admin:reset_password EMAIL=... PASSWORD=...`
- [x] Rake task: `admin:invite_volunteer`, `admin:promote` (bonus)
- [x] Documented Heroku invocation in `docs/development/ADMIN_USER_MANAGEMENT.md`
- [x] Tests: redirect-when-not-signed-in for every controller; sign-in / sign-out / require_admin! coverage
- [x] CHANGELOG updated
- [x] AI_03 (roles) updated to reflect 2-role reality
- [x] `CLAUDE.md` + `.github/copilot-instructions.md` updated to drop "future state" wording around auth

## Acceptance Criteria

- [x] Visiting any page when signed out redirects to sign-in
- [x] Volunteer can do all check-in/print/stats operations
- [x] Admin can do everything Volunteer can do (hierarchy via `volunteer?`)
- [x] `require_admin!` helper exists; admin-only routes will reject volunteers (Phase 5 will add real admin routes; helper is exercised in test)
- [x] Sign-in works on mobile (Picnic CSS responsive form)
- [x] All tests pass (50 runs, 114 assertions, 0 failures)

## What Was Implemented

### Phase 4.1 (complete)
- Removed orphan/broken fixtures (`students.yml` deleted; `cords.yml`, `brags.yml` rewritten; `graduates.yml` created).
- 26 controller tests across `GraduatesController` covering all routed actions + 2 in `PagesController`.
- Model tests for `Graduate`, `Brag`, `Cord`.
- Fixed: `config.hosts << "15ltws037665pmo.local"` was in `config/application.rb`, activating host authorization in test env (every request was 403). Moved to `config/environments/development.rb`.
- Test suite: **28 runs, 64 assertions, 0 failures**.

### Phase 4.2 (complete)
- Added `devise ~> 4.9` to Gemfile.
- `rails g devise:install` — initializer + locale.
- Configured `config.mailer_sender = 'no-reply@bucapandgown.com'`.
- Bumped `config.password_length` from `6..128` to `8..128`.
- `rails g devise User` + edited migration to add `role` integer column (default 0) with index. Ran migration.
- `User` model: enum `role: { volunteer: 0, admin: 1 }`. `volunteer?` overridden so admins also report `true` (role hierarchy).
- Skipped `:registerable` module + `devise_for :users, skip: [:registrations]` (invite-only).
- 8 user model tests covering enum, default role, validations, hierarchy.
- Discovered + fixed pre-existing schema drift: `degstatus`/`degstatusdesc` columns existed in production and in `db/schema.rb` but never had a Rails migration. Dev DB never grew them; once `db:migrate` regenerated `schema.rb` from dev DB state, the columns vanished from schema. Added idempotent migration `RestoreDegstatusToGraduates`.
- Test suite: **36 runs, 84 assertions, 0 failures**.

### Phase 4.3 (complete)
- `ApplicationController` now has `before_action :authenticate_user!` and a private `require_admin!` helper.
- Picnic-styled sign-in view at `app/views/users/sessions/new.html.erb`. Disabled the `_links.html.erb` partial (invite-only).
- Nav layout now shows `current_user.email` and a `button_to` sign-out when signed in.
- Created `lib/tasks/admin.rake` with: `admin:create`, `admin:invite_volunteer`, `admin:reset_password`, `admin:promote`.
- Documented usage (local + `heroku run`) in `docs/development/ADMIN_USER_MANAGEMENT.md`.
- Updated `docs/ai-context/AI_03_USER_ROLES_AND_PERMISSIONS.md` to reflect 2-role current state (was "planned").
- New `test/integration/authentication_test.rb`: 14 tests covering each protected route's redirect behavior, valid/invalid sign-in, sign-out, and `require_admin!` presence. Added `Devise::Test::IntegrationHelpers` to integration tests in `test_helper.rb`.
- Test suite: **50 runs, 114 assertions, 0 failures**.
- Spec deviation: kept Devise's `:passwords` routes mounted (only `:registrations` is skipped). Devise references `new_user_password_path` internally on failed sign-in flash; skipping it crashed the form. UI exposes no password-reset link.

## Spec Deviations
- **Phase 4.3:** Devise `:passwords` routes were originally going to be skipped along with `:registrations` since password reset is admin-driven via rake task. Devise internally references `new_user_password_path` on failed sign-in flash, so the routes had to stay mounted. The UI exposes no password-reset link, so the user-facing behavior matches the spec.

## Notes
- Update `CLAUDE.md`, `.github/copilot-instructions.md`, and `AI_03` to reflect 2-role hierarchy when this phase wraps.
- Consider a "kiosk mode" later if shared devices become painful.
- Password reset by email is deliberately deferred — `admin:reset_password` rake task is the manual path until then.
