# Phase 5 — Admin Interface (User Management + File Imports)

**Status:** In Progress
**Started:** 2026-04-26
**Completed:** _(not yet)_

## Goal
Build an admin-only interface that handles:
1. User management (create / edit / deactivate volunteers and admins)
2. Semester-prep file imports for `graduates`, `brags`, and `cords`

## Context
Each semester, a preparation process produces several files that need to be loaded into the database. Today this is done manually (likely via console or direct SQL). Goal is to catalog the process AND automate as much of it as makes sense via the admin UI.

> **TODO before this phase starts:** Catalog the current manual process. See `docs/development/SEMESTER_PREP_PROCESS.md` (to be created during Phase 5 planning).

## Scope

**In:**

### User Management
- `/admin/users` index, new, edit, destroy (or deactivate)
- Create user with email + role + temp password (or invitation email)
- Edit role
- Deactivate (soft-disable; preserves audit trail when audit lands)

### File Imports
- `/admin/imports` page with one upload widget per import type
- Accept **CSV and XLSX** (use `roo` gem for XLSX; `csv` stdlib for CSV). Detect format from file extension/MIME.
- Upload graduate roster file → preview → confirm → import
- Upload brag cards file → preview → confirm → import
- Upload cords file → preview → confirm → import
- Multiple roster file shapes are supported (main term roster, 3+3 UG list, late-add list). See sample files in `test/fixtures/files/imports/`.
- Preview shows: row count, sample rows, validation warnings, count of would-be inserts vs updates, **and gap warnings** (e.g., brags/cords referencing a BUID that does not exist in `graduates`).
- **Import strategy: upsert by `buid` for all file types.** Existing rows have non-PK fields updated; new rows are inserted. No row is ever destroyed by an import.
- Headers are matched **flexibly** (case-insensitive, whitespace-tolerant; map known aliases — e.g., `LevelCode` / `EffectLevel`, `College1` / `DegreeCollege1`, `SHBGAPP_FirstName` / `FirstName`).
- Each importer enforces a **2,500-row maximum** per upload. Files exceeding the cap are rejected at preview.
- Import errors shown clearly; partial-success handling
- Import history log (when, who, what file, row count, success/error, inserts vs updates)

### Roster Reset / Namespacing
- Admin-only **"Reset graduates"** action that truncates `graduates` (and cascades `brags`, `cords`). Requires typed confirmation. Logged in import history as a destructive action.
- **`graduation_term` namespacing on `graduates`** (string column, e.g., `"202620"` from `GraduationTerm` / `YearGraduating`): every imported row is stamped with the term selected at import time (defaulting to value parsed from the file when present).
- Reset action supports **scope = all** OR **scope = single graduation term**. Scoped reset deletes only graduates (and dependent brags/cords) for that term.
- Term selector visible on import preview ("Importing into term: 202620").

### Distribution Reporting Export
- `/admin/reports/graduates` page with CSV export actions (admin-only — not linked from volunteer nav)
- Export checked-in list, not-checked-in list, and all graduates
- Include key columns for operations: `buid`, name fields, degree/level fields, `checked_in`, `printed`, `graduation_term`
- Filterable by `graduation_term`

**Out (deferred):**
- Background job processing (Sidekiq) — start synchronous, move to async only if file sizes warrant
- Scheduled / automated imports (e.g., from S3 dropbox)
- Audit log beyond import history (separate phase)

## Pre-Flight Checks

- [x] Phase 4 (Devise) complete
- [ ] Semester prep process documented in `docs/development/SEMESTER_PREP_PROCESS.md`
- [ ] Sample files of each type committed to `test/fixtures/files/imports/` (sanitized — already provided: main term roster, 3+3 UG, late-add, brags, cords)- [x] Decision made on import strategy per file type — **upsert by `buid` across the board**
- [ ] Migration written: add `graduation_term` (string) to `graduates`, indexed; ensure `brags`/`cords` cascade-delete on graduate destroy
- [ ] `roo` gem added to Gemfile (XLSX parsing)
- [x] Sample files staged in `test/fixtures/files/` (sanitize before commit if needed)

## Deliverables

### Foundation
- [ ] `Admin::BaseController` with `before_action :require_admin!`
- [ ] `app/views/admin/` view directory + admin layout (or shared with main)
- [ ] Admin nav (separate from volunteer nav)
- [ ] Routes namespaced under `/admin`

### Users
- [ ] `Admin::UsersController` (index, new, create, edit, update, destroy/deactivate)
- [ ] Forms with Picnic CSS styling
- [ ] Tests for all admin actions + authorization

### Imports
- [ ] `Admin::ImportsController#index` (lists each upload widget + recent history + reset controls)
- [ ] One service per file type (`GraduateImporter`, `BragImporter`, `CordImporter`) in `app/services/`
- [ ] Shared `SpreadsheetParser` (or similar) wrapping CSV/XLSX reading and header normalization
- [ ] Each importer has: `parse(file)`, `preview` (returns counts + samples + warnings + insert/update split + gap report), `import!(graduation_term:)` (commits in a transaction)
- [ ] All importers use `upsert_all` (or per-row `find_or_initialize_by(buid:)`) keyed on `buid` (graduates) or `[buid, cord_type]` (cords)
- [ ] Brag and Cord importers emit a **gap report** listing BUIDs in the upload that are not present in `graduates` for the selected term — admin can choose to import-only-matched or abort
- [ ] 2,500-row cap enforced before any DB write
- [ ] `ImportLog` model: `user_id`, `import_type`, `filename`, `row_count`, `inserts`, `updates`, `graduation_term`, `succeeded`, `error_message`, `created_at`
- [ ] Upload uses Active Storage (already wired up in Rails 7.1)
- [ ] Tests per importer using fixture files (CSV + XLSX variants; main, 3+3, late-add)

### Roster Reset
- [ ] `Admin::RostersController#destroy` (or action on `ImportsController`) with typed-confirmation safeguard
- [ ] Supports `scope=all` and `scope=term&graduation_term=...`
- [ ] Cascading delete verified for brags + cords
- [ ] Records destructive event in `ImportLog` (`import_type: "reset"`)
- [ ] Tests for both scopes + admin-only access

### Reporting Export
- [ ] `Admin::ReportsController#graduates` page with export controls
- [ ] CSV endpoint(s) for checked-in, not-checked-in, and all graduates
- [ ] Export service or query object to keep CSV generation logic out of controllers
- [ ] CSV includes deterministic column order and header row
- [ ] Tests for CSV content, filtering, and admin-only access
- [ ] CHANGELOG updated

## Acceptance Criteria

- [ ] Volunteer hitting `/admin/*` is rejected (redirect or 403)
- [ ] Admin can create another admin
- [ ] Admin can upload each of the three file types (CSV or XLSX) and see a preview
- [ ] Re-uploading the same file does **not** create duplicates — existing rows are updated, new rows inserted
- [ ] Preview shows accurate insert vs update counts and any gap warnings (brags/cords without matching graduate)
- [ ] Files over 2,500 rows are rejected with a clear message
- [ ] Admin can confirm import and see the result reflected in `Graduate.count` etc.
- [ ] Failed import does not partially mutate the database (use a transaction)
- [ ] Admin can reset all graduates (with typed confirmation) AND reset a single graduation term
- [ ] Import history shows the last N imports with outcome (including resets)
- [ ] Admin can export CSV for checked-in and not-checked-in graduates, filterable by graduation term
- [ ] Exported CSV data matches database state at export time
- [ ] All tests pass

## Resolved Questions

_Answered 2026-04-24:_

| Question | Answer |
|---|---|
| File formats | **CSV and XLSX** (use `roo` for XLSX) |
| Source of truth | **Upsert** by `buid` |
| Mid-semester additions | **Yes** — supported via additional roster files (3+3 UG, late-add). Same upsert path. |
| Identifier collisions | **Update non-PK fields** |
| Brags file | Paired with graduates — surface a **gap report** when a brag references an unknown BUID |
| Cords file | Paired with graduates — same gap report |
| File size cap | **2,500 rows** per upload (synchronous import OK at this size) |
| Headers | **Flexible** — case-insensitive matching with known aliases |
| Dry-run / undo | **Preview is sufficient.** No undo (admin can re-import or reset). |
| CSV shape | See `test/fixtures/files/imports/` (Main term, 3+3 UG, Late-add, Brags, Cords) |
| Export location | **Admin only** — `/admin/reports` |
| Validation rules | Reject row when **BUID is missing**, **college code is unrecognized** (per `CollegeCodeTranslator`), or any **required field** is blank. Bad rows are **skipped with a warning** in the preview/log; import continues for valid rows. |
| Default graduation term | **Dropdown selector** on the import form. Options = distinct `graduation_term` values already present in the database, plus a "+ New term…" option that reveals a text input. Default selection = most recently imported term. If the uploaded file contains a `GraduationTerm` / `YearGraduating` column, the preview surfaces a warning when the file's term doesn't match the selected term (admin can override or change selection). |
| Late-add file | **Same `GraduateImporter`** with header aliases (`EffectLevel` → `LevelCode`, `DegreeCollege1` → `College1`, `Degree for Hood` → degree mapping) |

## Open Questions

_None remaining — ready to plan implementation._

_Answered 2026-04-26 (kickoff):_

| Question | Answer |
|---|---|
| Phase 5 sub-phase split | **Single block.** Implement users + imports + reset + reports as one phase, but commit at logical boundaries. |
| User deactivation | **Soft-deactivate** — add `active` boolean (default true). Inactive users cannot sign in. No hard destroy. |
| New-user password flow | **Admin sets a temp password.** User must change on first sign-in (new `must_change_password` flag, cleared on successful change). |
| Admin visual treatment | **Same look as the rest of the app.** No banner / color shift. |
| Semester prep doc | **Defer.** Treat the fixture files as the spec for now. |
| Cord `cord_type` source | **Parse from the uploaded file name** (basename minus extension, stripping trailing "Cords"/"Cord"). Admin can override at upload via a text field. |
| Cord BUID resolution | Lookup by `campusemail` first, then by exact `firstname + lastname` match, otherwise gap warning + row skip. |
| Brag `message` content | **Blank** at import. Operators may edit later. |
| Brag upsert strategy | **Delete-all-by-buid then insert** for the imported set. Note: a future differentiator column (e.g., `message` or another field) will be added so we can do per-row upsert. Tracked in `docs/BACKLOG.md`. |

## What Was Implemented

### Migrations
- `add_admin_fields_to_users`: `active:boolean` (default true), `must_change_password:boolean` (default false).
- `add_graduation_term_to_graduates`: `graduation_term:string`, indexed.
- `create_import_logs`: tracks every import + reset (user, type, filename, counts, term, success, warnings JSON).

### Models / Auth
- `User#active_for_authentication?` blocks deactivated sign-ins (locale `account_deactivated`).
- `ApplicationController#enforce_password_change!` redirects flagged users to `/password_change` until cleared.
- `Users::PasswordChangesController` (`update_with_password` + `bypass_sign_in`).
- `ImportLog` model with `serialize :warnings, coder: JSON`.

### Admin Foundation
- `Admin::BaseController` (require_admin!, admin layout).
- `app/views/layouts/admin.html.erb` mirrors application layout + admin nav.
- Admin nav links surfaced in main layout when `current_user.admin?`.

### Users (`Admin::UsersController`)
- index / new / create / edit / update / destroy(soft).
- Admin-set passwords flag `must_change_password = true`.
- Self-deactivation blocked.

### Imports (`Admin::ImportsController`)
- index + preview + create flow.
- 2,500-row cap enforced via `SpreadsheetParser`.
- Three importers wired into `IMPORTERS` registry.

### Importer Service Layer (`app/services/`)
- `BaseImporter` lifecycle (preview / import! / log_success! / log_failure!).
- `GraduateImporter`: `HEADER_ALIASES` for main / 3+3 / late-add shapes; `COLLEGE_NAME_ALIASES` resolves full college names to 2-letter codes; `reverse_degree_code` from hood description; height parser handles `5'10"` and integers; silently skips wholly-empty rows; `Graduate.upsert_all(record_timestamps: false)`.
- `BragImporter`: aliases incl. `Student First/Last/BUID`; gap report; insert/update split based on prior brag presence; delete-by-buid + `insert_all(record_timestamps: false)`.
- `CordImporter`: `derive_cord_type_from_filename` (strips `SAMPLE - ` prefix, `Cords?` suffix); admin override wins; BUID resolution via direct → email → firstname+lastname; `Cord.upsert_all(unique_by: [:buid, :cord_type], record_timestamps: false)`.

### Roster Reset (`Admin::RostersController`)
- Typed-confirmation safeguard (literal phrase `"RESET ROSTER"`).
- `scope=all` (truncate brags/cords/graduates in tx) and `scope=term` (delete by buid for that graduation_term + dependents).
- Logged as `ImportLog#import_type = "reset"`.

### Reporting (`Admin::ReportsController`)
- HTML + CSV at `/admin/reports/graduates`.
- Scopes: `all|checked_in|not_checked_in`. Term filter.
- CSV streamed via `find_each(batch_size: 500)`.

### Tests
- 36 new tests added across 8 files. Suite at 105 runs, 298 assertions, 0 failures.

### Friendly Search (post-MVP polish)
- `lib/graduate_search.rb` — single text input on `/start` accepts BUID / email / name. Two-pass name search:
  1. **Precise** ILIKE across `firstname`, `lastname`, `preferredfirst`, `preferredlast` (single-term avoids `fullname` to prevent middle-name false matches; two-term uses `fullname ILIKE '%a %b%'` for the cross-combination case).
  2. **Fuzzy** fallback (only if precise returns nothing): SOUNDEX + `pg_trgm` similarity, gated by length (single short tokens are skipped).
- Nickname expansion: ~80 nickname↔formal pairs (Bob↔Robert, Liz↔Elizabeth, Chris↔Christopher/Christina/Christian/Christine, …).
- Prefix-substitution table catches sound-alike spellings Soundex misses (Kris↔Chris↔Cris, Cathy↔Kathy, Phil↔Fil); substitution variants are re-fed through the nickname table so "Kris" → "Chris" → "Christopher/Christina/Christian".
- New migration `enable_fuzzy_search_extensions` enables `unaccent`, `pg_trgm`, `fuzzystrmatch` (idempotent).

### Importer hardening (post-MVP, from real-data dry run)
- `relax_graduate_string_limits` migration drops the legacy 50-char limit on 18 graduate columns (production data was overflowing).
- `GraduateImporter#build_order_id` produces `"<last-6-of-buid>-<jostens_height>"` when Jostens Height is present.
- `HEADER_ALIASES` split `jostens_height` and feet/inches columns from generic `height`.

### Admin Nav Dropdown
- Admin links collapsed into a `<details class="nav-dropdown"><summary class="nav-link">Admin▾` dropdown in both `application.html.erb` and `admin.html.erb`.
- Dropdown styling lives in `application.css`.

### System Test Infrastructure
- Removed `webdrivers` gem (conflicted with Selenium 4's built-in Selenium Manager).
- `application_system_test_case.rb` configured for headless Chrome.

### Gems
- `roo ~> 2.10` (XLSX), `csv ~> 3.3` (Ruby 3.4 stdlib warning silencer).

## Spec Deviations
- **Active Storage not used.** Uploads are processed in-memory from the multipart `Tempfile`; nothing is persisted. Spec listed Active Storage but the synchronous-import design makes persisted blobs unnecessary.

## Notes
- This is the first phase that will introduce `app/services/` to the project. Update `/patterns` skill when the directory is created.
- Consider whether the `Admin` interface should use a different visual treatment (e.g., a banner or color shift) so admins know they're in admin mode.
- Sample files received from operations (commit sanitized versions to `test/fixtures/files/imports/`):
  - `SAMPLE - May 2026.csv` — main term roster (~1,950 rows; full column set including height/weight)
  - `SAMPLE - 3 PLUS 3 UG.csv` — UG 3+3 add-list (similar shape, prefixed `Notes` column)
  - `SAMPLE - Late Add May 2026.csv` — late-add list (different shape: `Ceremony`, `EffectLevel`, `DegreeCollege1`, `Degree for Hood`)
  - `SAMPLE - Brag.xlsx` — brag cards (XLSX)
  - `SAMPLE - Cords.xlsx` — cords (XLSX)
- Header alias map will live alongside the importer (e.g., `GraduateImporter::HEADER_ALIASES`).
