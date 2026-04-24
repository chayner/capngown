# Changelog

All notable changes to Cap & Gown will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once releases begin.

---

## [Unreleased]

### Added
- Heroku Postgres upgraded from PG 15.17 (`postgresql-acute-23495`) to PG 16.13 (`postgresql-crystalline-90781`) via provision-copy-promote path. Maintenance window ~10 minutes. All 5 tables and 487 graduates / 59 brags / 0 cords verified equal post-copy.
- AI agent customization scaffolding: `CLAUDE.md`, `.github/copilot-instructions.md`, and `.claude/skills/` (debug, patterns, testing, deploy, performance, check-docs, phase-plan, phase-wrap).
- Documentation scaffolding under `docs/`: CHANGELOG, BACKLOG, PHASE_PROCESS, AI context bundle (AI_00–AI_07), DESIGN-GUIDELINES, LANGUAGE_STYLE_GUIDE.
- Phase specs for upcoming work (Postgres 16 upgrade, Heroku-24 stack upgrade + runtime modernization, Devise auth, admin interface).
- Explicit `Procfile` (`web` + `release: db:migrate`).
- Minimal `package.json` for Heroku Node pinning with `engines.node: 22.x`.

### Changed
- `config/database.yml` production block simplified to use `DATABASE_URL` only (removed hardcoded Heroku creds).
- Apex DNS for `bucapandgown.com` switched from wildcard CNAME to apex `ALIAS` at Squarespace; both apex and `www` now resolve directly to Heroku and serve the app (no www redirect).
- Phase 3 runtime modernization started locally:
	- Ruby upgraded from `3.2.3` to `3.3.10` (`.ruby-version`, `Gemfile`, lockfile Ruby metadata)
	- Bundler lock metadata upgraded from `2.3.7` to `2.7.2`
	- Puma constraint raised to `>= 7.0.3` and lockfile now resolves Puma `8.0.0`
	- Local runtime validation completed (`bin/rails test`, boot check, Puma boot, production assets precompile)
- Heroku stack/runtime deployment completed for Phase 3:
	- Buildpack order is now `heroku/nodejs` then `heroku/ruby`
	- App stack switched to `heroku-24` (release `v58`)
	- Deployed runtime verified on dyno: Ruby `3.3.10`, Bundler `2.7.2`, Node `22.22.2` via `engines.node: 22.x`
	- Phase 3 marked complete with deferred follow-up validation and warning cleanup tracked in backlog

### Removed
- `rails_12factor` gem (functionality is built into Rails 5+; `RAILS_LOG_TO_STDOUT` and `RAILS_SERVE_STATIC_FILES` already set in env).

### Fixed
- `config.hosts << "15ltws037665pmo.local"` was set globally in `config/application.rb`, which activated host authorization in the test environment and caused all integration tests to return 403. Moved to `config/environments/development.rb`.

### Phase 4.1 — Baseline test coverage (in progress)
- Replaced empty stub tests with real coverage:
	- `GraduatesControllerTest` — 26 smoke + behavior tests covering `start`, `list` (filters), `show`, `update`, `checkin`, `to_print`, `print`, `get_print_html`, `show_bulk`, `bulk_print`, `stats`.
	- `PagesControllerTest` — `welcome` and root redirect.
	- Model tests for `Graduate`, `Brag`, `Cord` (associations + validations).
- Replaced broken/orphan fixtures: deleted `students.yml` (no Student model), rewrote `cords.yml` (had `type:` instead of `cord_type:`) and `brags.yml`, added new `graduates.yml`.
- Suite now: 28 runs, 64 assertions, 0 failures.

### Phase 4.3 — Apply auth + UI + admin bootstrap (in progress)
- `ApplicationController` enforces `authenticate_user!` site-wide; private `require_admin!` helper added.
- Picnic-styled sign-in view; nav layout shows current user email + sign-out button when signed in.
- Rake tasks under `lib/tasks/admin.rake`: `admin:create`, `admin:invite_volunteer`, `admin:reset_password`, `admin:promote`.
- New docs: `docs/development/ADMIN_USER_MANAGEMENT.md` (local + Heroku command reference).
- `docs/ai-context/AI_03_USER_ROLES_AND_PERMISSIONS.md` rewritten from "planned" to current-state.
- New `test/integration/authentication_test.rb` covers redirect-when-signed-out for every protected route, valid/invalid sign-in, sign-out, and `require_admin!` presence.
- Test suite: 50 runs, 114 assertions, 0 failures.
- **Spec deviation:** kept Devise `:passwords` routes mounted (Devise references `new_user_password_path` internally); UI exposes no link to them.

### Phase 4.2 — Devise install (in progress)
- Added `devise ~> 4.9` gem.
- `User` model with email + password + `role` enum (`volunteer: 0`, `admin: 1`, default volunteer).
- Role hierarchy: `User#volunteer?` returns true for admins as well as volunteers.
- Devise initializer: `mailer_sender = no-reply@bucapandgown.com`, `password_length = 8..128`.
- Sign-up disabled (`:registerable` module skipped, `devise_for :users, skip: [:registrations]`) — accounts are invite-only.
- 8 user model tests; total suite now 36 runs, 84 assertions, 0 failures.
- Restored `degstatus` and `degstatusdesc` columns on `graduates` (existed in production but missing from dev DB; idempotent migration).

### Known follow-ups (post-Phase 3)
Remaining from the Phase 3 release build (Heroku, release v58):
- Informational warning that Bundler changed from `2.3.7` to `2.7.2`.
- Heroku suggests upgrading to Ruby `3.3.11` (currently deployed `3.3.10`).

Tracked in [PHASE_3_HEROKU_24_UPGRADE.md](planning/phases/PHASE_3_HEROKU_24_UPGRADE.md).
