# Changelog

All notable changes to Cap & Gown will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once releases begin.

---

## [Unreleased]

### Phase 5 — Admin interface (in progress)
- **Edit graduate names from the show page**: New `GraduatesController#edit` + `update` paths permit `firstname`, `lastname`, `preferredfirst`, `preferredlast` so volunteers can fix sticker errors on the fly without re-importing. New `app/views/graduates/edit.html.erb` form with grouped fieldsets (formal vs. preferred), responsive two-column layout, and inline hints. "Edit Names" button surfaced in the "Full Grad Info" header on the show page. The legacy height-only modal update path is preserved (no flash, redirect-to-show). Three controller tests added (renders, updates name fields, rejects mass-assignment of `buid`).
- **Print queue click reliability fix**: `/print` polls `/get_print` every 5 seconds and was unconditionally replacing `#to-print` innerHTML, which sometimes destroyed "Print All" / graduate-name links between `mousedown` and `mouseup` (clicks silently dropped; manual refresh "fixed" it). Polling now pauses on hover/mousedown over `#to-print` and only swaps innerHTML when the response actually differs.
- **Stats dashboard master/doctorate breakdown bugfix**: Production rosters use `levelcode = "GR"` for both master's and doctorate graduates, but the stats controller was filtering on legacy `"GR-M"` / `"GR-D"` values that don't exist — so the Master and Doctorate counts (both in the "Students Already Printed" summary and the "Printed Data Over Time" table) always showed 0, and the time-series Total didn't equal UG + MA + DR. New `Graduate.master` / `Graduate.doctorate` / `Graduate.undergraduate` scopes derive the level from `degree1` via `DegreeHoodTranslator::DEGREE_HOOD_MAP[:level]` (`MASTER_DEGREE_CODES` / `DOCTORATE_DEGREE_CODES` constants). `GraduatesController#stats` now uses these scopes everywhere. Regression test added.
- **Sticker layout overhaul**:
  - **List view (`/list`)**: Combined `Deg` + `Major` columns into a single `Program` column to reduce horizontal scroll on smaller screens. Major shows on top with a vertically-centered hat icon (grad only) to its left; degree code shows below as smaller, muted text.
  - **Sticker (`_badge`)**: Undergrad now shows just the major (no "in [degree]"). Grad shows hat icon + degree CODE + "in" + major (e.g. "MBA in Marketing" instead of "Master of Business Administration in Marketing").
  - **Sticker hood color**: For graduate students without an `orderid`, the bottom row now displays the assigned hood color next to the height, so volunteers can grab the right hood for a bulk/non-assigned gown.
  - **Show page**: Expanded "Full Grad Info" panel to show all available `graduates` columns (BUID, name parts, diploma name, email, level, degree code + name, major, college code + name, hood color, honors, height, order ID, graduation term, degstatus, formatted timestamps).
- **`graduates.degree1` is now always stored as a code** (e.g. "MBA", "DPT") regardless of whether the spreadsheet supplied a code or a full description. New `GraduateImporter#normalize_degree_code` reverse-maps full names to codes via `DegreeHoodTranslator`. Ensures `hoodcolor` lookup works for every roster shape. New `Graduate#degree_code` model helper provides the same defensive normalization at display time.
- **Degree-name aliases** (`DegreeHoodTranslator::DEGREE_NAME_ALIASES` + `code_from_name` class method) for descriptions that don't exactly match the canonical map text: "Juris Doctor" → JD, "Master of Arts" → MA, "Post Professional Doctor of Occupational Therapy" → DOT. Add new entries here when an import surfaces an unrecognized description.
- **`SpreadsheetParser` alias-priority bugfix** (regression): when multiple input columns aliased to the same canonical key (e.g. both `Degree1` and `Degree Description` mapped to canonical `degree1`), the LAST column read silently overwrote earlier ones — so "Legal Studies" clobbered "BS" for 1,409 undergrad records, leaving `degree1` and `hoodcolor` blank. `build_canonical_lookup` now respects alias-list order: the highest-priority alias wins, demoted columns fall through to their normalized header name. Two regression tests added.
- **`graduates:backfill_degree_codes` rake task** (`bin/rails graduates:backfill_degree_codes [DRY_RUN=true]`): one-shot cleanup that converts existing rows whose `degree1` holds a full description back to the code and fills in the missing `hoodcolor`.

- **Brag importer is now non-destructive** (`brags.transaction_id` column + unique index added in `add_transaction_id_to_brags`). The Bruin Brag export now includes `Note` and `Transaction ID` columns; `BragImporter` upserts by `transaction_id` instead of delete-all-by-buid, so re-uploading a smaller file no longer wipes earlier brags. Rows missing a Transaction ID are skipped with a warning; in-file Transaction ID duplicates are deduped (last-write wins is rejected, first wins). Also added `index_brags_on_buid`.
- **Friendlier name handling**: when `preferredfirst` is missing on import, derive a nickname from the campus email local part (`pref_first.last@bruins.belmont.edu`) — the part before the first dot, capitalized — unless it matches `firstname` (case-insensitive) or is too short to be a real name. New `Graduate.preferred_first_from_email` helper.
- **Sticker shows formal name as a smaller secondary line** when preferred first/last differs from formal first/last, so volunteers call the graduate by their preferred name while bag stuffers can still match the formal name printed on the cap & gown bag. New `Graduate#formal_name_differs_from_preferred?`, `.formal-name` style, updated `_badge.html.erb`.
- **Defensive name sanitization**: `Graduate.sanitize_preferred_first` / `sanitize_preferred_last` strip a duplicated surname (or leading given name) so a roster row with `preferredfirst="Cameron Bateman"` no longer prints as "BATEMAN, CAMERON BATEMAN". Applied at import time in `GraduateImporter#normalize_row` and at display time via `display_preferred_first` / `display_preferred_last` (used in the badge, list, and print-list views).
- **`graduates:backfill_nicknames` rake task** (`bin/rails graduates:backfill_nicknames [DRY_RUN=true]`): one-shot backfill for existing graduates whose preferredfirst is blank and who have a campus email.
- **`graduates:sanitize_preferred_names` rake task** (`bin/rails graduates:sanitize_preferred_names [DRY_RUN=true]`): one-shot cleanup for legacy rows whose preferredfirst already contains the duplicated surname.
- **Operational doc** `docs/development/SEMESTER_PREP_PROCESS.md` — step-by-step playbook for loading a new graduation term (reset → graduates → brags → cords → verify), with troubleshooting table.
- **Friendly graduate search** (`lib/graduate_search.rb`): single search box on `/start` accepts BUID, email, or name. Name search is two-pass: precise ILIKE first (with nickname expansion + spelling-prefix substitutions); falls back to fuzzy SOUNDEX + trigram similarity only when the precise pass returns no rows. Nicknames table (~80 pairs, both directions). Prefix-substitution table covers Kris↔Chris↔Cris, Cathy↔Kathy, Phil↔Fil. Single-term searches deliberately exclude the `fullname` column (which contains middle names) to avoid false positives. Three new PG extensions enabled via `enable_fuzzy_search_extensions` migration: `unaccent`, `pg_trgm`, `fuzzystrmatch`.
- **Admin nav dropdown**: Admin links collapsed into a `<details>`/`<summary>` dropdown in both main and admin layouts. Picnic-friendly CSS in `application.css`; closes when another item is clicked.
- **Importer hardening from real Belmont data**:
  - `relax_graduate_string_limits` migration drops the legacy 50-char limit on 18 columns (production data exceeded several limits, causing `PG::StringDataRightTruncation`).
  - `GraduateImporter` builds `orderid` as `"<last-6-of-buid>-<jostens_height>"` when Jostens Height is present; splits separate `height_ft` / `height_in` columns; new `parse_feet_inches` helper.
- **System test infrastructure**: removed conflicting `webdrivers` gem; Selenium 4's bundled Selenium Manager handles driver downloads. `application_system_test_case.rb` switched to headless Chrome.
- **User management** (`Admin::UsersController`): index/new/create/edit/update/destroy; admin-set temporary passwords flagged with `must_change_password`; soft-deactivation via `users.active`; admins cannot deactivate themselves.
- **Forced password change**: `ApplicationController#enforce_password_change!` redirects flagged users to `Users::PasswordChangesController#edit` until they set a new password (uses `update_with_password`, then `bypass_sign_in`).
- **Devise `active_for_authentication?`**: deactivated users cannot sign in (locale message `account_deactivated`).
- **File imports** (`Admin::ImportsController`): preview-then-confirm flow for graduate/brag/cord rosters, capped at 2,500 rows per file (CSV + XLSX via `roo`).
- **Importer service layer** (new `app/services/`): `BaseImporter` lifecycle (preview + import! + ImportLog), `GraduateImporter` (header aliases for main/3+3/late-add shapes; full-college-name → 2-letter code resolver), `BragImporter` (delete-by-buid + insert; gap report), `CordImporter` (`cord_type` from filename or override; BUID lookup by email then exact name).
- **Roster reset** (`Admin::RostersController`): typed-confirmation reset (`"RESET ROSTER"`); supports scope=all and scope=term; logged as `ImportLog#import_type = "reset"`.
- **CSV reporting** (`Admin::ReportsController`): graduate export with scope filters (`all|checked_in|not_checked_in`) and graduation_term filter; streamed via `find_each(batch_size: 500)`.
- **`ImportLog` model**: tracks every import + reset (user, import_type, filename, row_count, inserts/updates/skipped, graduation_term, success flag, error_message, JSON-serialized warnings).
- **`graduates.graduation_term`** added (string + index) so imports can stamp records and admin tools can filter by term.
- **Spreadsheet parser** (`lib/spreadsheet_parser.rb`): unified CSV/XLSX reader with header normalization, alias mapping, and 2,500-row cap.
- New tests across importers, admin controllers, password-change flow, user management, and graduate search — suite at 105 runs, 298 assertions, 0 failures.
- New gems: `roo ~> 2.10`, `csv ~> 3.3` (pinned to silence Ruby 3.4 stdlib warning).
- Backlog: brag uniqueness differentiator column to enable proper update detection (currently delete-by-buid + reinsert).

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
- Dedicated `app/views/layouts/devise.html.erb` for unauthenticated pages (no main nav, focused sign-in card).
- `ApplicationController#resolve_layout` switches Devise controllers to the `devise` layout automatically.
- `config.scoped_views = true` so Devise renders our custom `users/sessions/new`.
- Mobile hamburger menu fixed: scoped flex layout to desktop only; mobile dropdown now stacks items full-width.
- Flash message styling unified (`.flash-notice`, `.flash-alert`) across both layouts.
- Rake tasks under `lib/tasks/admin.rake`: `admin:create`, `admin:invite_volunteer`, `admin:reset_password`, `admin:promote`.
- New docs: `docs/development/ADMIN_USER_MANAGEMENT.md` (local + Heroku command reference).
- `docs/ai-context/AI_03_USER_ROLES_AND_PERMISSIONS.md` rewritten from "planned" to current-state.
- New `test/integration/authentication_test.rb` covers redirect-when-signed-out for every protected route, valid/invalid sign-in, sign-out, and `require_admin!` presence.
- `config/application.rb` requires `devise` explicitly before `Bundler.require` to avoid dev-reload route ordering issues.
- Test suite: 50 runs, 114 assertions, 0 failures.
- **Spec deviation:** kept Devise `:passwords` routes mounted (Devise references `new_user_password_path` internally); UI exposes no link to them.

### Phase 4.2 — Devise install (in progress)

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
