# Semester Prep Process

How to load a new graduation term's data into Cap & Gown.

This document is the operational playbook for the admin running prep before each commencement. The fixture files committed under `test/fixtures/files/` are the canonical examples of every shape this app accepts.

---

## Overview

Each commencement requires three kinds of data:

| Data | Source | File shape | Importer |
|---|---|---|---|
| **Graduates** | Registrar | CSV (main), CSV (3+3 UG), CSV (late-add) | `GraduateImporter` |
| **Brag cards** | Operations team | XLSX | `BragImporter` |
| **Cords** | Operations team | XLSX (one file per cord type) | `CordImporter` |

All loading happens through the admin UI at `/admin/imports`. There is no console step for an ordinary semester. The `Admin::RostersController` (`/admin/rosters`) handles destructive resets when prep starts from scratch.

---

## Prerequisites

- Admin account (see `docs/development/ADMIN_USER_MANAGEMENT.md`).
- Files from the registrar and ops team gathered in one place. Sanitize and rename them so the cord file basenames describe the cord type (e.g., `Honors Cords.xlsx`, `Phi Kappa Phi.xlsx`).
- The graduation term you'll be loading into (e.g., `202620` for Spring 2026).

---

## Step 1 — Decide whether to reset

If the term has never been loaded, skip this step.

If you're re-loading a term from scratch (e.g., the registrar reissued a corrected file):

1. Go to `/admin/rosters`.
2. Choose **scope = term** and select the graduation term.
3. Type the literal phrase `RESET ROSTER` to confirm.
4. Submit. All graduates with that `graduation_term` are deleted, along with their dependent brags and cords.

`scope = all` exists for full wipes (e.g., end-of-year cleanup) but should rarely be needed.

Every reset is recorded in `ImportLog` with `import_type = "reset"`.

---

## Step 2 — Load graduates

Order matters: graduates first, then brags and cords (which both reference graduate BUIDs).

The graduate importer accepts three file shapes — main term roster, 3+3 UG, and late-add — and converges them through `GraduateImporter::HEADER_ALIASES`. You don't need to reformat the registrar's file. You just need to upload it.

For each file:

1. Go to `/admin/imports`.
2. In the **Graduates** widget, select the graduation term (or pick **+ New term…** and type it).
3. Choose the file (CSV).
4. Click **Preview**. The preview shows:
   - Row count (must be ≤ 2,500 — split larger files).
   - Insert vs update split.
   - Skipped row count + warnings (missing BUID, unknown college code).
   - Sample rows.
   - **Term mismatch warning** if the file's `GraduationTerm` column doesn't match the term you selected.
5. Review. If good, click **Confirm import**.

The importer:
- Normalizes headers (case-insensitive, alias-mapped).
- Resolves college codes — direct match first, then full-name alias lookup via `COLLEGE_NAME_ALIASES`. Rows with unknown codes are skipped with a warning.
- Builds `orderid` as `<last-6-of-buid>-<jostens_height>` when Jostens Height is present.
- Parses height from any of: `TotalHeight`, `Jostens Height`, or paired `Height Ft` / `Height In` columns.
- Reverse-maps degree-for-hood text to a degree code when `Degree1` is missing.
- Stamps every row with the selected `graduation_term`.
- Upserts by `buid` (no row is destroyed).

Repeat for each shape (main → 3+3 → late-add). Files can be re-uploaded safely; existing rows are updated, new rows inserted.

---

## Step 3 — Load brag cards

1. Go to `/admin/imports`.
2. In the **Brags** widget, select the same graduation term.
3. Choose the brag XLSX file and click **Preview**.
4. Check the **gap report** — BUIDs in the file with no matching graduate. These rows are skipped. If the gaps look wrong, fix the brag file (or load missing graduates first) and retry.
5. Confirm.

**Strategy note:** the brag importer **deletes all existing brags for the BUIDs in the file** and re-inserts them. The brags table currently has no per-row differentiator column, so this is the only safe replacement strategy. If the same brag file is uploaded twice, the second run produces the same result. Tracked in `docs/BACKLOG.md` as "Brag differentiator column."

---

## Step 4 — Load cords

Cords are loaded **one file per cord type**. The cord type is derived from the filename (basename minus extension, with a leading `SAMPLE - ` and a trailing `Cord(s)` stripped). Examples:

| Filename | Derived `cord_type` |
|---|---|
| `Honors Cords.xlsx` | `Honors` |
| `Phi Kappa Phi.xlsx` | `Phi Kappa Phi` |
| `SAMPLE - Cords.xlsx` | _(empty — must override)_ |

For each cord file:

1. Go to `/admin/imports`.
2. In the **Cords** widget, select the graduation term.
3. Choose the file. The form shows the auto-derived cord type.
4. If the auto-derived type is wrong or empty, type a **Cord Type override** before previewing.
5. Click **Preview**. The cord importer resolves each row's BUID via:
   1. Direct `BUID` column if present.
   2. `Email` → `graduates.campusemail` lookup.
   3. Exact `firstname + lastname` match.
   4. Otherwise: gap report + skip.
6. Confirm.

Cord upserts are keyed on `[buid, cord_type]` so re-loading the same file is safe.

---

## Step 5 — Verify and export

1. `/admin/imports` shows the most recent `ImportLog` entries with row counts and warnings.
2. `/admin/reports/graduates` exports CSVs filtered by `graduation_term` and check-in scope (`all` / `checked_in` / `not_checked_in`). Use this to spot-check counts against the registrar's totals before commencement.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Whole file skipped with "missing BUID" | Header row not detected (extra rows above headers) | Open the file, delete pre-header rows so the header is row 1, re-export. |
| Many "unknown college code" warnings | Late-add file uses full college names | The importer's `COLLEGE_NAME_ALIASES` covers known names; unknown ones are skipped with a warning naming the value — add to the alias map and redeploy. |
| All graduates look "updated" not "inserted" | You're re-running a file that already loaded | Expected. Upserts are idempotent. |
| Brag/cord file gap report is huge | Loaded brags/cords before graduates, or file is for a different term | Load graduates for the term first; verify the term selector matches the file. |
| Preview is rejected at 2,500 rows | File too large | Split the file by college or alphabetically and load each part. |
| Cord import skips every row with no `cord_type` | Filename normalization stripped to empty | Use the **Cord Type override** field. |
| `PG::StringDataRightTruncation` | A column the importer writes is still 50 chars (legacy) | Add the column to `db/migrate/20260426150000_relax_graduate_string_limits.rb`-style migration. |

---

## Reference

- Importers: `app/services/{graduate,brag,cord}_importer.rb`, `app/services/base_importer.rb`
- Header normalization + 2,500-row cap: `lib/spreadsheet_parser.rb`
- College code translator: `lib/college_code_translator.rb`
- Sample fixtures (canonical shapes): `test/fixtures/files/SAMPLE - *.csv` and `*.xlsx`
- Phase 5 spec: `docs/planning/phases/PHASE_5_ADMIN_INTERFACE.md`
