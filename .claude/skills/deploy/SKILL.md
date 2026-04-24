---
name: deploy
description: Pre-commit checks, commit format, release tagging, and deployment workflow for Cap & Gown. Use when committing, tagging, or deploying.
disable-model-invocation: false
---

# Deploy & Release

## Pre-Commit Checklist

Before every commit:

### 1. Tests Pass
```bash
bin/rails test    # 0 failures, 0 errors required
```

### 2. Documentation Review

Evaluate which docs need updating (not every commit needs all of these):

- [ ] **CHANGELOG.md** — Almost always. Add entry under `[Unreleased]`.
- [ ] **Phase spec files** (`docs/planning/phases/`) — Update checkboxes, "What Was Implemented"
- [ ] **BACKLOG.md** (`docs/BACKLOG.md`) — Item implemented, new idea identified, feature deferred
- [ ] **AI Context Bundle** (`docs/ai-context/`) — State changed, new patterns, features added/removed

**Guideline:** Bug fixes and minor UI tweaks typically only need CHANGELOG. New features or architectural changes typically touch 3-5 docs.

## Commit Message Format

```
[Type]: [Brief title under 50 chars]

[1-2 sentence summary]

Key changes:
- [Change 1]
- [Change 2]

Tests: [X] runs, 0 failures
```

**Types:** `Phase X.X`, `Fix`, `Feature`, `Docs`, `Refactor`, `Chore`

**Rules:**
- Under 500 chars total
- No emoji
- Type must be one of the above

## Release Tagging

**Never push a tag without updating CHANGELOG.md first.**

```bash
# 1. Update CHANGELOG.md — move [Unreleased] items to version section
# 2. Commit the CHANGELOG
git add docs/CHANGELOG.md
git commit -m "Docs: Update CHANGELOG for vX.X.X"

# 3. Push to main
git push origin main

# 4. Create annotated tag with release notes
git tag -a vX.X.X -m "Release vX.X.X: [Title]

[Feature 1]:
- Details

Tests: [X] runs, 0 failures"

# 5. Push the tag
git push origin vX.X.X
```

## Deployment Workflow (Heroku)

**App:** `belmont-cap-and-gown` (URL: https://bucapandgown.com)

**Normal path:**
1. Commit and push to `origin main` (GitHub)
2. GitHub Actions CI runs tests automatically
3. On CI pass, deploy to Heroku

**Never push directly to Heroku** unless explicitly approved as an emergency hotfix.

> **Note:** GitHub Actions CI is not yet configured for this repo. See `docs/BACKLOG.md`. Until then, the local `bin/rails test` run is the gate.

## Web Process & Procfile

A `Procfile` lives at the repo root with:
```
web: bundle exec rails server -p $PORT -e $RAILS_ENV
release: bundle exec rails db:migrate
```

The `release` line auto-runs migrations on every deploy. If you add a destructive migration, coordinate with maintenance mode.

`Procfile.dev` is **not** used — importmap and Picnic CDN mean there are no asset watchers to run alongside `bin/rails server`. Add one only if a JS/CSS bundler is introduced later.

## Two-Phase Deployment Pattern

When a migration depends on a rake task (data transformation that must run BEFORE the migration):

**Phase 1:** Deploy the rake task only (no migration)
```bash
git push origin main
heroku run rake your_namespace:your_task
```

**Phase 2:** Deploy the migration (after task has run)
```bash
git push origin main
# Migration runs automatically on deploy
```

Use this any time a migration would fail or corrupt data if run on the current schema without preparation. Especially relevant here because the legacy schema has unusual conventions (`buid` PK, no timestamps).

## Heroku Operational Commands

```bash
heroku logs --tail
heroku run bin/rails console
heroku run bin/rails db:migrate
heroku pg:psql
heroku config           # check env vars
heroku ps               # see dynos and memory
```

## Production Verification After Deploy

- [ ] App responds (`curl https://your-app.herokuapp.com/start`)
- [ ] No new errors in `heroku logs --tail`
- [ ] A real graduate lookup works
- [ ] Print queue loads
