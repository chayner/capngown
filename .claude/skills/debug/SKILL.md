---
name: debug
description: Debugging tips, emergency commands, and common gotchas for Cap & Gown. Use when investigating errors or unexpected behavior.
disable-model-invocation: false
---

# Debugging Tips

## Emergency Commands

```bash
bin/rails routes | rg problematic_route                       # Check route exists
echo "Graduate.count" | bin/rails console                     # Check database state
echo "Graduate.reflect_on_all_associations.map(&:name)" | bin/rails console
echo "Graduate.find_by(buid: 'B00610448')&.attributes" | bin/rails console
tail -n 50 log/development.log                                # Check recent logs
```

## General
- **Console testing:** `echo "code" | bin/rails console`
- Logs: `log/development.log`
- When something "silently fails," check the logs first

## Cap & Gown Specific Gotchas (CRITICAL)

### `Graduate` Primary Key Is `buid` (string), Not `id`
```ruby
Graduate.find(1)                       # WRONG — there is no integer id
Graduate.find_by(buid: "B00610448")    # CORRECT
Graduate.find("B00610448")             # Also works because PK is buid
```
Routes declare `param: :buid`, so `graduate_path(@g)` produces `/graduates/B00610448`, not `/graduates/1`.

### `Cord` Has No `id`
```ruby
# db/schema.rb: create_table "cords", id: false
cord = graduate.cords.first
cord.id   # => nil — there is no id column
```
Use the composite `[buid, cord_type]` for identity. The unique index `index_cords_on_buid_and_cord_type` enforces this.

### No Timestamps on Legacy Tables
`graduates`, `brags`, and `cords` have **no `created_at` / `updated_at`**.
```ruby
Graduate.order(:created_at)   # PG::UndefinedColumn!
```
The closest things to timestamps you have are `checked_in` and `printed`.

### `checked_in` and `printed` Are Datetime State Flags
- `WHERE checked_in IS NULL` = not yet checked in
- `WHERE printed IS NULL` = not yet printed
- Don't add a separate boolean — just check NULL.
- "Clearing" a flag means setting the column back to `nil` (see `bulk_print` action's `print=clear` param).

## Picnic CSS, Not Tailwind
- Class names come from Picnic (`button`, `success`, `error`, `warning`, `pseudo`, `dangerous`).
- Custom overrides: `app/assets/stylesheets/application.scss` (or `.css`).
- Don't try Tailwind utilities (`bg-blue-500`, `flex`, etc.) — they will not compile.

## Importmap (No Bundler)
```bash
bin/importmap pin some-package    # add JS dep
bin/importmap json                # see what's pinned
```
- All JS deps come through `config/importmap.rb`.
- Pinned files live in `vendor/javascript/`.
- No `package.json`, no `yarn`/`npm`.

## Rails Enum & Model Convention Gotchas

**Polymorphic associations require valid class names** (when added later):
```ruby
author_type: "User"    # Valid — real model name
author_type: "Staff"   # NameError — no Staff model!
```

**Model methods ≠ database columns — never use methods in WHERE clauses:**
```ruby
# If `full_name` is a method (not a column):
Graduate.where(full_name: "John Doe")  # => PG::UndefinedColumn!

# Always verify the column exists in db/schema.rb before using in .where()
```

## `dependent:` Strategy vs Column Constraints

| Column Constraint | Safe `dependent:` Values | Unsafe |
|---|---|---|
| `null: true` (nullable) | `:nullify`, `:destroy`, `:delete` | — |
| `null: false` / `NOT NULL` | `:destroy`, `:delete` | `:nullify` → `NotNullViolation` |

`Cord.buid` is `null: false` — never `:nullify` a `cords` association.

## Turbo Streams & Turbo Frames
- **`link_to` with `method: :post` does NOT work in Turbo.** Use `button_to`.
- **`button_to` `data: { turbo: false }`** applies to the **button**, not the form. Use `form: { data: { turbo: false } }`.
- **Links inside `<turbo-frame>` navigate within the frame** — add `target="_top"` to escape.
- **File upload with Turbo:** Add `data-turbo="false"` AND `multipart: true` to form.

## Print Workflow Specifics
- `GraduatesController#get_print_html` renders a partial as a raw HTML string. The print page polls/loads this partial and triggers `window.print()`. If something "doesn't print," verify:
  1. Is `checked_in` set on the graduate?
  2. Is `printed` still NULL? (`?printed=show` reveals already-printed records.)
  3. Does the partial render server-side? `curl http://localhost:3000/get_print` should return the HTML.

## Bulk Actions (BUID list pattern)
- `show_bulk` / `bulk_print` accept `params[:buids]` as a comma-separated string.
- Always `params[:buids]&.split(',')` (with safe-nav) — empty string would otherwise blow up.
- Test with: `?buids=B00610448,B00489639`

## View-Data Contract
- Check key types: Ruby symbols vs strings (`row[:key]` != `row['key']`)
- `assert_response :success` does NOT verify the rendered content. Use `assert_select` or `assert_match`.

## New Code Can Surface Pre-Existing Bugs
When a new feature causes a regression, the bug may be in **pre-existing code** now exercised for the first time:
1. Read the full stack trace — is the error in your new code or existing code?
2. If existing code: fix the root cause, don't work around it
3. The regression test belongs in the existing feature's test file

## Adding to This File
When you discover a new gotcha, add it here AND a one-liner to `.github/copilot-instructions.md` Common Gotchas. Both files are equally important — Copilot reads the latter, Claude reads this one in detail.
