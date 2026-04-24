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

### Changed
- `config/database.yml` production block simplified to use `DATABASE_URL` only (removed hardcoded Heroku creds).
- Apex DNS for `bucapandgown.com` switched from wildcard CNAME to apex `ALIAS` at Squarespace; both apex and `www` now resolve directly to Heroku and serve the app (no www redirect).

### Removed
- `rails_12factor` gem (functionality is built into Rails 5+; `RAILS_LOG_TO_STDOUT` and `RAILS_SERVE_STATIC_FILES` already set in env).

### Fixed
- _(none yet)_

### Known build warnings (deferred to Phase 3)
From the Phase 1 release deploy log (Heroku, release v50):
- Bundler `2.3.7` is older than the previously deployed `2.3.25`; recommend bumping to a current bundler.
- Ruby `3.2.3` is approaching EOL (Dec 25, 2026); upgrade to `3.3.x`.
- Heroku recommends Puma `7.0.3+` for Router 2.0 compatibility (currently resolves `6.5.0`).
- Node default version drifted (22.11.0 → 24.13.0); pin via `heroku/nodejs` buildpack.
- Stack `heroku-22` upgrade available (target: `heroku-24`).

All five are tracked in [PHASE_3_HEROKU_24_UPGRADE.md](planning/phases/PHASE_3_HEROKU_24_UPGRADE.md).
