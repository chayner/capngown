# Agent Instructions for Cap & Gown

This document guides AI coding agents working in the `Cap & Gown` Ruby on Rails application.

---

## Architecture & Stack

- **Framework:** Ruby on Rails 7.1, Ruby 3.2.3
- **Database:** PostgreSQL
- **Frontend:** Picnic CSS (CDN), Sprockets, Turbo/Hotwire
- **JS:** Import maps (no bundler), Stimulus
- **Auth:** Devise (Phase 4 complete) — site-wide `authenticate_user!`, two roles, invite-only
- **Background Jobs:** None today
- **Hosting:** Heroku (live at `belmont-cap-and-gown`)
- **Dev debug:** `pry-rails`, `debug`, `bin/rails console`
- **Console testing:** `echo "Graduate.count" | bin/rails console`
- **Tests:** `bin/rails test`
- **Logs:** `log/development.log`

---

## What This App Does

**Cap & Gown** is a web-based app that assists in the check-in and printing of stickers for the distribution of caps & gowns at **Belmont University**. The goal is to streamline the distribution process while making it fun, easy, and meaningful for our graduates.

Primary flows: graduate lookup by BUID/name → check-in → sticker print queue → bulk print actions → stats dashboard.

---

## Terminology

| Term | Meaning |
|------|---------|
| **BUID** | Belmont University ID — string identifier; the primary key for `Graduate` |
| **Graduate** | A degree candidate eligible to receive cap & gown regalia |
| **Brag** | Optional recognition card associated with a graduate |
| **Cord** | An honor cord a graduate is entitled to wear (typed by `cord_type`) |
| **Print queue** | Checked-in graduates whose stickers haven't yet been printed (`printed IS NULL`) |
| **Level code** | `UG` undergraduate, `GR-M` master's, `GR-D` doctorate |

---

## Role Hierarchy

Devise auth is enforced site-wide (Phase 4). Two roles:

| Role | Access | Guards |
|------|--------|--------|
| **Volunteer** | Look up graduates, check-in, mark printed, bulk ops, stats | `before_action :authenticate_user!` (default) |
| **Admin** | Everything Volunteer can do + user mgmt + file imports | `before_action :require_admin!` |

Admin returns `true` for all volunteer-level checks. Account creation and password resets are admin-only via `bin/rails admin:*` rake tasks.

---

## Data & Domain Patterns

- **`Graduate.primary_key = "buid"`** (string, limit 50). Routes use `param: :buid`.
- **`Cord` has no `id` column** — composite identity `[buid, cord_type]`.
- **No `created_at`/`updated_at`** on `graduates`, `brags`, `cords`.
- **`checked_in` and `printed`** are nullable datetimes used as state flags.
- **Naming:** `*_code` for short enum-like strings (e.g., `levelcode`, `college1`).
- **No soft deletes.**

---

## Key Services / Lib

| File | Purpose |
|------|---------|
| `lib/college_code_translator.rb` | College code → full name |
| `lib/degree_hood_translator.rb` | Degree code → academic hood color |

**Rules:** Domain translation logic belongs in `lib/`, never duplicated in views or controllers.

---

## Critical Rules (Always Apply)

### Data & Code Rules
1. **Run `bin/rails test` before ANY commit** — 0 failures, 0 errors required
2. **Never assume model methods exist** — always check the model file and `db/schema.rb` first
3. **Patterns before invention** — search for existing patterns before creating new ones
4. **Write tests AS you build** — Not after. Every new controller action, service, model method, or code branch gets a test immediately.

### Behavioral Rules
5. **Pause frequently** — Before implementation, at decision points, after each logical chunk.
6. **User reports error -> follow Bug/Error Response Process** — Write a failing test BEFORE fixing. Check for ALL occurrences of the same pattern. Document the lesson.
7. **Never create orphan files** — Every partial, helper, service MUST be integrated before moving on.
8. **Update docs as you build** — Not just at phase wrap.
9. **Spec deviations require approval** — STOP before building something different from the spec.

### Maintenance Rule
10. **Keep these instructions current** — When a new pattern, preference, or gotcha is discovered, update the appropriate docs file.

---

## Key Conventions

- **Service objects:** Plain Ruby classes in `lib/` or `app/services/` (create when needed), public `call` or `perform`
- **Controller structure:** RESTful actions, `before_action` for finders/auth guards, instance variables for views
- **Test style:** Minitest, fixtures (not factories), `setup` method, descriptive test names
- **Views:** ERB + Picnic CSS classes, partials in the controller's view folder
- **Stimulus:** One controller per behavior, `data-controller` on the element, `data-action` for events
- **Flash messages:** `:notice` for success, `:alert` for errors

---

## Common Gotchas

- **`Graduate` PK is `buid` (string), not `id`.** Use `Graduate.find_by(buid: ...)`, never `Graduate.find(numeric_id)`. Routes declare `param: :buid`.
- **`Cord` has no `id` column.** `cord.id` is `nil`. Use `[buid, cord_type]` for identity.
- **No timestamps on `graduates`/`brags`/`cords`.** `.order(:created_at)` will raise.
- **`checked_in` / `printed` are timestamps used as flags.** `WHERE printed IS NULL` = not yet printed.
- **Picnic CSS, not Tailwind.** Use Picnic classes (`button`, `success`, `error`, `pseudo`); add overrides in `app/assets/stylesheets/`. Tailwind utilities won't compile.
- **Importmap, not a bundler.** Add JS deps via `bin/importmap pin <pkg>`.
- **Turbo POST buttons:** `link_to` with `method: :post` does NOT work in Turbo. Always use `button_to`.
- **`button_to` data attributes:** `data: { turbo: false }` applies to the **button**, not the **form**. Use `form: { data: { turbo: false } }`.
- **Idempotent actions don't need POST:** Use GET + `link_to` for read-only actions like health checks.
- **Model methods ≠ database columns:** Never use model methods in `.where()`. Verify the column in `db/schema.rb` first.
- **Polymorphic / heterogeneous data in views:** Guard with `respond_to?` when different record types may have different methods.

---

## Deployment Workflow

**Target path:**
1. Commit and push to `origin main` (GitHub)
2. GitHub Actions CI runs tests (not yet configured — see `docs/BACKLOG.md`)
3. On CI pass, deploy to Heroku

**Never push directly to Heroku** unless explicitly approved as an emergency hotfix.

---

## Commit Message Format
```
[Type]: [Brief title under 50 chars]

[1-2 sentence summary]

Key changes:
- [Change 1]
- [Change 2]

Tests: [X] runs, 0 failures
```
**Types:** `Phase X.X`, `Fix`, `Feature`, `Docs`, `Refactor`, `Chore`. Under 500 chars total. No emoji.

---

## Pre-Commit Documentation Review

Before committing, evaluate which docs need updating:

- [ ] **CHANGELOG.md** — Almost always updated. Add entry under `[Unreleased]`.
- [ ] **Phase spec files** — Update checkboxes, "What Was Implemented" sections.
- [ ] **BACKLOG.md** — Backlog item implemented, new idea identified, or feature deferred.
- [ ] **AI Context Bundle** (`docs/ai-context/AI_00` through `AI_07`) — State changed, new patterns, features added/removed.

**Guideline:** Bug fixes and minor UI tweaks typically only need CHANGELOG. New features or architectural changes typically touch 3-5 docs.

---

## Testing Rules

### Test-As-You-Go
1. Every new model gets a model test
2. Every new controller action gets a controller test
3. Every new service gets a service test
4. Every new parameter/filter gets test coverage
5. Every new code branch needs a test
6. Run `bin/rails test` after each significant change
7. Every route should have test coverage

### Modified Behavior Requires Tests
"All tests pass" does not mean "all new behavior is tested." Check: new params? New filters? New branches? New output?

### Model Method Verification Rule
**NEVER assume a model has a method. ALWAYS check the model file and schema first.** This matters extra here — `Graduate` has no timestamps, `Cord` has no `id`.

---

## Emergency Debug Commands
```bash
bin/rails routes | rg route_name
echo "Graduate.count" | bin/rails console
echo "Graduate.reflect_on_all_associations.map(&:name)" | bin/rails console
tail -n 50 log/development.log
```

---

## Appendix: Performance (Heroku)

### Key Patterns
- Avoid `.to_a` on large queries (the graduate list can run into thousands)
- Batch processing (50 records)
- Pass only rendered data to views
- 15-second timeout protection

### Heroku Config
```ruby
# config/puma.rb
workers 1
threads 3, 3
```

---

For more detailed information, see:
- `CLAUDE.md` — Always-loaded agent instructions with skills index
- `docs/ai-context/AI_00_APP_OVERVIEW.md` — App context bundle (start here)
- `docs/ai-context/AI_01` through `AI_07` — Detailed context files
- `docs/planning/phases/` — Phase spec files
- `docs/development/DESIGN-GUIDELINES.md` — Visual design reference
- `docs/development/LANGUAGE_STYLE_GUIDE.md` — Voice, tone, word choices
- `docs/BACKLOG.md` — Deferred items and known debt
- `docs/PHASE_PROCESS.md` — How phases are planned and tracked
