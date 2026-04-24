# Agent Instructions for Cap & Gown

This is the **always-loaded core**. Detailed guidance is available as skills — invoke the relevant skill BEFORE starting work on that topic.

---

## On-Demand Skills Index

**Invoke these skills when working on the corresponding topic:**

| Topic | Skill | When to Invoke |
|-------|-------|---------------|
| Patterns & conventions | `/patterns` | Creating new files, services, components |
| Testing rules | `/testing` | Writing or reviewing tests |
| Phase planning | `/phase-plan` | Starting or planning any phase/sub-phase |
| Phase wrap | `/phase-wrap` | Wrapping or completing any phase |
| Debugging tips | `/debug` | Investigating errors or unexpected behavior |
| Deploy & release | `/deploy` | Committing, tagging, deploying |
| Check docs | `/check-docs` | Reviewing and consolidating documentation |
| Performance | `/performance` | Performance optimization, memory issues |

### Trigger Phrases

When the user says any of these phrases, invoke the corresponding skill:

| User Says | Invoke |
|-----------|--------|
| "check docs", "review documentation" | `/check-docs` |
| "wrap", "wrap the phase" | `/phase-wrap` |
| "commit", "deploy", "release", "tag" | `/deploy` |
| Starting a new phase or sub-phase | `/phase-plan` |
| "error", "exception", "broken", "not working", "bug", "crash", "failing", user shares a stack trace or screenshot of an error | `/debug` + follow **Bug/Error Response Process** below |

---

## Bug/Error Response Process

**MANDATORY checklist whenever an error is reported or discovered:**

1. **Load `/debug` skill immediately** — read it before investigating
2. **Reproduce first** — write a failing test that captures the exact bug before touching any app code. If you can't write a test yet, at minimum confirm the error locally
3. **Identify root cause** — read the full stack trace; is the error in new code or pre-existing code now exercised for the first time?
4. **Check for all occurrences** — search the full codebase for the same pattern before fixing just the reported instance (grep broadly)
5. **Fix the root cause** — don't work around it
6. **Verify the test now passes** — run the specific test file first
7. **Ask "why didn't I catch this?"** — document the answer
8. **Update docs** — add the lesson to:
   - `.claude/skills/debug/SKILL.md` (detailed explanation + code example)
   - `.github/copilot-instructions.md` Common Gotchas (one-liner)
9. **Run full test suite** — `bin/rails test`, 0 failures required before stopping

**Never skip steps 2, 7, or 8.** These are the steps most commonly omitted under time pressure and they prevent the bug from recurring.

---

## Architecture & Stack

- **Framework:** Ruby on Rails 7.1, Ruby 3.2.3
- **Database:** PostgreSQL
- **Frontend:** Picnic CSS (via CDN), Sprockets asset pipeline, Turbo/Hotwire
- **JS:** Import maps (no bundler), Stimulus
- **Auth:** Devise (Phase 4) — site-wide `authenticate_user!`, two roles (`Admin`, `Volunteer`), invite-only via rake tasks. See `docs/development/ADMIN_USER_MANAGEMENT.md`.
- **Background Jobs:** None today — Sidekiq + Redis would be the planned addition
- **Hosting:** Heroku — live at `belmont-cap-and-gown` (https://bucapandgown.com). Web command comes from the `heroku/ruby` buildpack default unless overridden by `Procfile`.
- **Dev debug:** `pry-rails`, `debug` gem, `bin/rails console`
- **Console testing:** `echo "Graduate.count" | bin/rails console`
- **Tests:** `bin/rails test` (no `bin/test` wrapper exists yet)
- **Logs:** `log/development.log`

### Key Directories

- `app/models/` — ActiveRecord models (`Graduate`, `Brag`, `Cord`)
- `app/controllers/` — RESTful controllers
- `app/views/` — ERB templates; partials live in their controller's view folder (e.g., `graduates/_search.html.erb`)
- `app/javascript/` — Stimulus controllers, importmap-loaded
- `lib/` — Domain helpers (`college_code_translator.rb`, `degree_hood_translator.rb`)
- `config/routes.rb` — Rails DSL routes

---

## What This App Does

**Cap & Gown** is a web-based app that assists in the check-in and printing of stickers for the distribution of caps & gowns at **Belmont University**. The goal is to streamline the distribution process while making it fun, easy, and meaningful for our graduates.

Primary flows:
1. **Check-in** — Look a graduate up by BUID or name, confirm their record, mark them as checked in, capture height for gown sizing.
2. **Sticker print queue** — Checked-in graduates flow into a print list that prints labels for their cap/gown packet.
3. **Brag cards & cords** — Graduates may have associated brag (recognition) cards and honor cords that print/display alongside their main record.
4. **Stats** — Real-time progress dashboard for staff: how many graduates have been printed, broken down by college, degree level, and program.

---

## Terminology

| Term | Meaning |
|------|---------|
| **BUID** | Belmont University ID — string identifier (e.g., `B00610448`); the primary key for `Graduate` |
| **Graduate** | A degree candidate eligible to receive cap & gown regalia |
| **Brag** | An optional recognition card associated with a graduate (multiple per graduate possible) |
| **Cord** | An honor cord a graduate is entitled to wear (typed by `cord_type`; multiple per graduate) |
| **Hood color** | Color of the academic hood, derived from degree (see `lib/degree_hood_translator.rb`) |
| **College code** | Short code for the academic college (e.g., `CL`, `MB`); translated via `lib/college_code_translator.rb` |
| **Level code** | `UG` = undergraduate, `GR-M` = master's, `GR-D` = doctorate |
| **Print queue / "to print"** | The list of checked-in graduates whose stickers haven't been printed yet |
| **Bulk print** | Multi-graduate print/clear-print action driven by a list of comma-separated BUIDs |

---

## Role Hierarchy

Devise auth is **enforced site-wide** (Phase 4 complete). Two roles:

| Role | Access | Guards |
|------|--------|--------|
| **Volunteer** | Look up graduates, check-in, mark printed, bulk operations, stats dashboard | `before_action :authenticate_user!` (default in `ApplicationController`) |
| **Admin** | Everything Volunteer can do + user management + file imports (Phase 5) | `before_action :require_admin!` |

`current_user.volunteer?` returns true for both volunteers and admins (admin is a superset). `current_user.admin?` is true only for admins.

Account creation and password resets are admin-only via rake tasks (see `docs/development/ADMIN_USER_MANAGEMENT.md`). There is no public sign-up.

---

## Data & Domain Patterns

- **`Graduate.primary_key = "buid"`** (string, limit 50) — NOT a numeric `id`. Always pass `buid:` when building paths/finders.
- **`Brag` and `Cord`** join to graduates via `buid` (string FK) — `has_many :brags, primary_key: "buid", foreign_key: "buid"`.
- **`Cord` has no `id`** — composite identity is `[buid, cord_type]` with a unique index. Do not assume `cord.id` exists.
- **No `created_at` / `updated_at`** on the legacy tables (`graduates`, `brags`, `cords`). Don't reference timestamps that don't exist.
- **No soft deletes.**
- **Date/time markers:** `checked_in` and `printed` are nullable datetime columns used as state flags (NULL = not yet, present = done at this time).

---

## Key Services

| Service | Purpose |
|---------|---------|
| `lib/college_code_translator.rb` | Maps short college codes to full names (e.g., `MB` → `Massey College of Business`). Use `CollegeCodeTranslator.translate_full(code)`. |
| `lib/degree_hood_translator.rb` | Maps degree codes to academic hood colors. |

**Rules:** Domain translation logic belongs in `lib/`, not duplicated in views or controllers. If you find yourself writing a `case college_code` block in a view, use the translator instead.

---

## Critical Rules (Always Apply)

### Data & Code Rules
1. **Run `bin/rails test` before ANY commit** — 0 failures, 0 errors required
2. **Never assume model methods exist** — always check the model file and `db/schema.rb` first. Especially important here: `Graduate` is sparse (`buid` PK, no timestamps), `Cord` has no `id`.
3. **Patterns before invention** — search for existing patterns before creating new ones
4. **Write tests AS you build** — Not after. Every new controller action, service, model method, or code branch gets a test immediately. The current test suite is sparse — adding tests is itself a high-value activity.

### Behavioral Rules
5. **Pause frequently** — Before implementation, at decision points, after each logical chunk. Never barrel through multi-step work without checking in.
6. **User reports error -> follow Bug/Error Response Process** — Load `/debug`, write a failing test BEFORE fixing, check for all occurrences, ask "why didn't I catch this?", update debug skill and copilot-instructions with the lesson.
7. **Never create orphan files** — Every partial, helper, service MUST be integrated (rendered, called, used) before moving on. If deferred, explicitly note it.
8. **Update docs as you build** — Not just at phase wrap. Update CHANGELOG and feature docs incrementally.
9. **Spec deviations require approval** — STOP before building something different from the spec. Explain the deviation, propose alternatives, get explicit user approval, then update the spec.

### Maintenance Rule
10. **Keep instructions current** — When a new pattern, preference, or gotcha is discovered, route it to the appropriate skill file. Review skills during every phase wrap.

---

## Common Gotchas (Cap & Gown specific)

- **`Graduate` primary key is `buid` (string), not `id`.** Routes use `param: :buid`. Never call `Graduate.find(numeric_id)` — use `Graduate.find_by(buid: ...)`.
- **`Cord` has no `id` column** (`create_table "cords", id: false`). Don't assume `cord.id` works.
- **No timestamps on `graduates`, `brags`, `cords`.** Don't `.order(:created_at)` on these tables.
- **`checked_in` / `printed` are timestamps used as flags.** `WHERE printed IS NULL` means "not printed". Don't add a separate boolean column.
- **Picnic CSS, not Tailwind.** Style with Picnic classes (`button`, `pseudo`, `success`, `error`) and the `app/assets/stylesheets/application.scss` overrides. Don't add Tailwind utility classes — they won't compile.
- **Importmap, no bundler.** Add JS deps via `bin/importmap pin <pkg>`, not `yarn`/`npm`.
- **Turbo POST buttons:** `link_to` with `method: :post` does NOT work in Turbo — Turbo ignores `data-method`. Use `button_to` (creates a real `<form method="post">`).
- **`button_to` data attributes:** `data: { turbo: false }` on `button_to` applies to the **button**, not the **form**. Use `form: { data: { turbo: false } }` instead.
- **Idempotent actions don't need POST:** For "test connection" or health checks, use GET + `link_to`. No form = no CSRF = no Turbo form issues.
- **Model methods ≠ database columns:** Never use model methods in `.where()` clauses. Always verify the column exists in `db/schema.rb` before adding `.where(column: value)`.

---

## Deployment Workflow

**Target path:**
1. Commit and push to `origin main` (GitHub)
2. GitHub Actions CI runs tests automatically (CI not yet configured — see backlog)
3. On CI pass, deploy to Heroku

**Never push directly to Heroku** unless explicitly approved as an emergency hotfix.

---

For more detailed information, see:
- `docs/ai-context/AI_00_APP_OVERVIEW.md` — App context and overview
- `docs/ai-context/AI_01` through `AI_07` — Detailed context files
- `docs/planning/phases/` — Phase spec files (one per phase)
- `docs/development/DESIGN-GUIDELINES.md` — Visual design reference
- `docs/development/LANGUAGE_STYLE_GUIDE.md` — Voice, tone, word choices
- `docs/BACKLOG.md` — Deferred items and known debt
- `docs/PHASE_PROCESS.md` — How phases are planned and tracked
