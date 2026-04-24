# Phase 4 — Devise Auth (Admin + Volunteer)

**Status:** Planned
**Started:** _(not yet)_
**Completed:** _(not yet)_

## Goal
Add Devise authentication and a two-role hierarchy (`Admin`, `Volunteer`) so the app is no longer publicly reachable.

## Context
The app is currently open. The original spec called for a 3-role hierarchy (Volunteer / Coordinator / Admin). After re-scoping with the user, **only two roles are needed**:
- **Admin** — user management + file imports (handled by Phase 5)
- **Volunteer** — everything else (look up, check in, mark printed, view stats, bulk operations)

## Scope

**In:**
- Add `devise` gem
- Generate `User` model with `role` enum (`admin`, `volunteer`)
- Default role: `volunteer`
- Sign-in / sign-out / forgot-password flows
- `before_action :authenticate_user!` on every controller (except sign-in pages)
- Helper methods: `current_user.admin?`, `current_user.volunteer?` (admin returns true for both)
- A seed/console-only path to create the first admin
- Update layout: show signed-in user + sign-out link in nav
- Tests: model + controller authorization tests

**Out (deferred):**
- Admin UI for managing users → Phase 5
- File import UI → Phase 5
- OAuth / SSO (use email + password only)
- Password complexity / 2FA
- Coordinator role (re-introduce later if needed)
- Audit log of who-did-what (track in BACKLOG)

## Pre-Flight Checks

- [ ] Phase 2 + 3 complete (don't mix infra and feature work)
- [ ] Baseline test coverage exists for existing actions (so authorization changes can be verified)
- [ ] User decides: invite-only vs self-signup

## Deliverables

- [ ] `devise` added to Gemfile, `bundle install`
- [ ] `bin/rails g devise:install`
- [ ] Devise initializer configured (mailer sender, secret_key)
- [ ] `User` model with email + encrypted_password + role enum
- [ ] Migration: `users` table with `role` integer column, default 0 (volunteer)
- [ ] `User#admin?` returns true for admins; `User#volunteer?` returns true for both admins and volunteers (hierarchy)
- [ ] `ApplicationController#before_action :authenticate_user!`
- [ ] `before_action :require_admin!` helper available for admin-only actions
- [ ] Sign-in view styled with Picnic CSS to match app
- [ ] Nav shows current user + sign-out link
- [ ] Seeds or rake task to create the first admin
- [ ] Tests: User model, authentication flow, redirect-when-not-signed-in
- [ ] CHANGELOG updated
- [ ] AI_03 (roles) updated to reflect 2-role reality

## Acceptance Criteria

- [ ] Visiting any page when signed out redirects to sign-in
- [ ] Volunteer can do all check-in/print/stats operations
- [ ] Admin can do everything Volunteer can do
- [ ] Admin-only routes (Phase 5) reject volunteers with 403 / redirect
- [ ] Sign-in works on mobile (volunteers will use phones/tablets)
- [ ] All tests pass

## Open Questions
- **First-admin bootstrap:** seed file? rake task? `heroku run` console command? (Recommend rake task for repeatability.)
- **Self-signup or admin-invite-only?** (Lean: invite-only — volunteers shouldn't create their own accounts.)
- **Password reset email:** which mailer? SendGrid? Heroku's mailgun? (Could be deferred if admin-managed.)
- **Sessions:** per-device or shared? Distribution-day machines may be shared.
- **Password complexity:** enforce length only, or require symbols?

## What Was Implemented
_(Filled in as work progresses.)_

## Spec Deviations
_(Add immediately when implementation differs.)_

## Notes
- Update `CLAUDE.md`, `.github/copilot-instructions.md`, and `AI_03` to reflect 2-role hierarchy when this phase wraps.
- Consider a "kiosk mode" later if shared devices become painful.
