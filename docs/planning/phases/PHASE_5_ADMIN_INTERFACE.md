# Phase 5 — Admin Interface (User Management + File Imports)

**Status:** Planned
**Started:** _(not yet)_
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
- Upload graduate roster file → preview → confirm → import
- Upload brag cards file → preview → confirm → import
- Upload cords file → preview → confirm → import
- Preview shows: row count, sample rows, validation warnings, count of would-be inserts vs updates
- Import strategy per file: replace-all vs upsert (TBD per file type)
- Import errors shown clearly; partial-success handling
- Import history log (when, who, what file, row count, success/error)

**Out (deferred):**
- Background job processing (Sidekiq) — start synchronous, move to async only if file sizes warrant
- Scheduled / automated imports (e.g., from S3 dropbox)
- CSV export of distribution data
- Audit log beyond import history (separate phase)

## Pre-Flight Checks

- [ ] Phase 4 (Devise) complete
- [ ] Semester prep process documented in `docs/development/SEMESTER_PREP_PROCESS.md`
- [ ] Sample files of each type committed to `test/fixtures/files/` (sanitized)
- [ ] Decision made on import strategy per file type (replace vs upsert)

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
- [ ] `Admin::ImportsController#index` (lists each upload widget + recent history)
- [ ] One service per file type (e.g., `GraduateImporter`, `BragImporter`, `CordImporter`) in `app/services/`
- [ ] Each importer has: `parse(file)`, `preview` (returns counts + samples + warnings), `import!` (commits)
- [ ] `ImportLog` model: `user_id`, `import_type`, `filename`, `row_count`, `succeeded`, `error_message`, `created_at`
- [ ] Upload uses Active Storage (already wired up in Rails 7.1)
- [ ] Tests per importer using fixture files
- [ ] CHANGELOG updated

## Acceptance Criteria

- [ ] Volunteer hitting `/admin/*` is rejected (redirect or 403)
- [ ] Admin can create another admin
- [ ] Admin can upload each of the three file types and see a preview
- [ ] Admin can confirm import and see the result reflected in `Graduate.count` etc.
- [ ] Failed import does not partially mutate the database (use a transaction)
- [ ] Import history shows the last N imports with outcome
- [ ] All tests pass

## Open Questions

These need to be answered during Phase 5 planning, after the semester prep process is cataloged:

- **File formats:** CSV? Excel? Custom? (Determines parser dependency — `csv` stdlib vs `roo` gem.)
- **Source of truth:** does each new roster *replace* the existing graduates, or *upsert*?
- **Mid-semester additions:** can a graduate be added incrementally without re-importing the whole roster?
- **Identifier collisions:** if a row's BUID exists, do we update non-PK fields or skip?
- **Brags file:** is it always paired with a graduates file, or independent?
- **Cords file:** same question.
- **File size:** typical row count? (If <10k, synchronous is fine. If >50k, need background job.)
- **Headers:** consistent column names across semesters, or will the importer need flexibility?
- **Validation rules:** what makes a row invalid (missing BUID? bad college code?) and what should happen — skip, error, or admin review?
- **Dry-run / undo:** is "preview" enough or do we also need "undo last import"?

## What Was Implemented
_(Filled in as work progresses.)_

## Spec Deviations
_(Add immediately when implementation differs.)_

## Notes
- This is the first phase that will introduce `app/services/` to the project. Update `/patterns` skill when the directory is created.
- Consider whether the `Admin` interface should use a different visual treatment (e.g., a banner or color shift) so admins know they're in admin mode.
