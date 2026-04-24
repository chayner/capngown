---
name: testing
description: Test rules, coverage requirements, and validation patterns for Cap & Gown. Use when writing or reviewing tests.
disable-model-invocation: false
---

# Testing Rules

## Current State

The `test/` tree exists but is largely empty (default Rails scaffold). Building test coverage is itself a high-value activity — when you touch a controller or model, leave a test behind.

## Test-As-You-Go (Non-Negotiable)

Write tests AS you build — not after. Every new feature gets tested before moving on.

| Change Type | Test Required |
|-------------|--------------|
| New model | Model test |
| New controller action | Controller test |
| New service / lib module | Service test |
| New parameter/filter | Parameter coverage |
| New code branch | Branch coverage |
| New route | Route coverage |
| New view logic | View assertion |

**"All tests pass" does not mean "all new behavior is tested."** After making changes, ask yourself: new params? New filters? New branches? New output? If yes, write tests for each.

## Pre-Commit Testing

```bash
bin/rails test                      # MUST run before every commit
bin/rails test test/models           # Model tests only
bin/rails test test/controllers      # Controller tests only
bin/rails test test/integration      # Integration tests
bin/rails test test/system           # System (browser) tests
```

**Zero failures, zero errors required.** No exceptions.

## Model Method Verification Rule

**NEVER assume a model has a method. ALWAYS check the model file and schema first.**

This matters extra in Cap & Gown because:
- `Graduate` has no `id` (PK is `buid`)
- `Cord` has no `id` column at all
- None of the legacy tables (`graduates`, `brags`, `cords`) have `created_at` / `updated_at`

Before writing ANY test that calls a model method:
1. Open the model file and verify the method exists
2. Check `db/schema.rb` for column names — don't confuse model methods with database columns
3. Never use model methods in `.where()` clauses

```bash
# Verify model methods
rg "def " app/models/graduate.rb

# Verify database columns
rg "create_table.*graduates" -A 30 db/schema.rb
```

## Fixture Setup for Cap & Gown

Fixtures need to honor the `buid` primary key:

```yaml
# test/fixtures/graduates.yml
sample:
  buid: B00000001
  firstname: Sample
  lastname: Graduate
  levelcode: UG
  college1: CL
  degree1: BA
```

```yaml
# test/fixtures/brags.yml
sample_brag:
  buid: B00000001
  name: Mom
  message: Congrats!
```

```yaml
# test/fixtures/cords.yml
# Cords have no id — fixture key is just a label, not stored
sample_cord:
  buid: B00000001
  cord_type: honors
```

Access in tests: `graduates(:sample)`, `brags(:sample_brag)`.

## View Test Coverage

When a controller sets instance variables, verify the view actually USES them correctly:

```ruby
# Insufficient — assert_response :success doesn't check content
assert_response :success

# Correct
assert_select "h1", "Check-in"
assert_match "B00000001", response.body
```

## Test Style

- **Minitest with fixtures** — not RSpec, not FactoryBot.
- Fixtures live in `test/fixtures/`
- Use `setup` for test initialization
- Descriptive test names: `test "list filters by college code"`

## Coverage Audit

```bash
# Find untested controller actions
rg "def (index|show|create|update|destroy|new|edit|checkin|print|list|stats|to_print|bulk_print|show_bulk)" app/controllers/ | while read line; do
  file=$(echo $line | cut -d: -f1)
  method=$(echo $line | grep -oE '(index|show|create|update|destroy|new|edit|checkin|print|list|stats|to_print|bulk_print|show_bulk)')
  controller=$(basename $file .rb)
  test_file="test/controllers/${controller}_test.rb"
  if [ -f "$test_file" ]; then
    if ! rg -q "$method" "$test_file"; then
      echo "MISSING TEST: $controller#$method"
    fi
  else
    echo "MISSING TEST FILE: $test_file"
  fi
done
```

## When User Reports a Bug

1. Write a **failing test** that reproduces the bug BEFORE fixing code
2. Fix the code
3. Verify the test passes
4. Ask "why didn't my existing tests catch this?" — add the answer to the `/debug` skill
5. Run full suite: `bin/rails test`
