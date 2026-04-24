# Changelog

All notable changes to Cap & Gown will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once releases begin.

---

## [Unreleased]

### Added
- AI agent customization scaffolding: `CLAUDE.md`, `.github/copilot-instructions.md`, and `.claude/skills/` (debug, patterns, testing, deploy, performance, check-docs, phase-plan, phase-wrap).
- Documentation scaffolding under `docs/`: CHANGELOG, BACKLOG, PHASE_PROCESS, AI context bundle (AI_00–AI_07), DESIGN-GUIDELINES, LANGUAGE_STYLE_GUIDE.
- Phase specs for upcoming work (Postgres 16 upgrade, Heroku-24 stack upgrade, Devise auth, admin interface).
- Explicit `Procfile` (`web` + `release: db:migrate`).

### Changed
- `config/database.yml` production block simplified to use `DATABASE_URL` only (removed hardcoded Heroku creds).

### Removed
- `rails_12factor` gem (functionality is built into Rails 5+; `RAILS_LOG_TO_STDOUT` and `RAILS_SERVE_STATIC_FILES` already set in env).

### Fixed
- _(none yet)_
