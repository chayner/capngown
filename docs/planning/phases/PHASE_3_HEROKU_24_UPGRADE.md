# Phase 3 — Heroku Stack 22 → 24 + Runtime Modernization

**Status:** Planned
**Started:** _(not yet)_
**Completed:** _(not yet)_

## Goal
Move `belmont-cap-and-gown` from `heroku-22` to `heroku-24` and clear the runtime warnings reported in the most recent build log:

1. Bundler is old (`2.3.7`); bump to a current bundler.
2. Ruby `3.2.3` is approaching EOL (Dec 25, 2026); upgrade to a current `3.3.x` release.
3. Puma `6.5.0` is below Heroku's recommended `7.0.3+` for Router 2.0.
4. Node is auto-installed at the buildpack default and not pinned.

These four items are deeply entwined with the stack move (heroku-24 supports newer Ruby, newer Node, and Router 2.0 alignment matters more on the new stack), so they're bundled here.

## Context
- Current stack: `heroku-22` (Ubuntu 22.04) → target `heroku-24` (Ubuntu 24.04)
- Risk is low: importmap (no JS bundling), Picnic CSS via CDN, native deps limited to `pg` and `nokogiri`.
- Build warnings to address come straight from the Phase 1 deploy log (see CHANGELOG entry).

## Scope

**In:**
- Stack: `heroku-22` → `heroku-24`
- Ruby: `3.2.3` → latest `3.3.x` (e.g., `3.3.6`)
- Bundler: `2.3.7` → current (`2.5.x` or `2.6.x` — match what `bundle update --bundler` resolves)
- Puma: `>= 5.0` (resolves 6.5.0) → `>= 7.0.3`
- Node: pin via `heroku/nodejs` buildpack ahead of `heroku/ruby` with a pinned version in `package.json` engines field
- Smoke test

**Out (deferred):**
- Rails upgrade (7.1 → 7.2 / 8.x) — separate phase
- Major nokogiri / pg gem updates beyond what the bundler upgrade pulls

## Pre-Flight Checks

- [ ] Phase 2 (PG upgrade) complete and stable
- [ ] Not in distribution week
- [ ] Confirm latest Ruby `3.3.x` patch supported on heroku-24 (Heroku dev center)
- [ ] Confirm Puma 7.x compatibility with our config (`config/puma.rb` is stock — should be fine)
- [ ] PG backup captured (`heroku pg:backups:capture`) as a precaution
- [ ] Local `rbenv install 3.3.x` works

## Deliverables

### Bundler
- [ ] `gem install bundler && bundle update --bundler`
- [ ] Verify `BUNDLED WITH` line in `Gemfile.lock` updated
- [ ] `bin/rails test` passes locally

### Ruby
- [ ] `rbenv install 3.3.x`; update `.ruby-version`
- [ ] Update `ruby "3.3.x"` line in `Gemfile`
- [ ] `bundle install` clean
- [ ] `bin/rails test` passes locally
- [ ] `bin/rails server` starts cleanly

### Puma
- [ ] Bump `gem "puma", ">= 7.0.3"` in `Gemfile`
- [ ] `bundle update puma`
- [ ] `bin/rails server` starts cleanly under new Puma
- [ ] Review `config/puma.rb` for any deprecations

### Node pinning
- [ ] Add `heroku/nodejs` buildpack ahead of `heroku/ruby`:
  ```bash
  heroku buildpacks:add --index 1 heroku/nodejs -a belmont-cap-and-gown
  ```
- [ ] Add minimal `package.json` with `engines.node` pinned (e.g., `"node": "22.x"`)
- [ ] Verify `package.json` doesn't break the asset precompile

### Stack
- [ ] `heroku stack:set heroku-24 -a belmont-cap-and-gown`
- [ ] Empty commit + push to trigger rebuild
- [ ] Build succeeds with no warnings
- [ ] Smoke test passes (graduate lookup, check-in, print queue, stats)
- [ ] CHANGELOG updated

## Acceptance Criteria

- [ ] `heroku apps:info` reports `Stack: heroku-24`
- [ ] Build log shows no warnings about bundler, Ruby EOL, Puma version, or Node default
- [ ] App responds normally on https://bucapandgown.com
- [ ] No new errors in `heroku logs --tail` for 30 min post-deploy
- [ ] All tests pass locally and (when CI exists) in CI

## Runbook

```bash
APP=belmont-cap-and-gown

# --- Local prep (one PR, in this order) ---

# 1. Bundler bump
gem install bundler
bundle update --bundler
bin/rails test
git add Gemfile.lock && git commit -m "Chore: Bump bundler"

# 2. Ruby upgrade
rbenv install 3.3.6   # or current latest 3.3.x
echo "3.3.6" > .ruby-version
sed -i '' 's/ruby "3.2.3"/ruby "3.3.6"/' Gemfile
bundle install
bin/rails test
git add .ruby-version Gemfile Gemfile.lock && git commit -m "Phase 3: Upgrade Ruby to 3.3.6"

# 3. Puma upgrade
sed -i '' 's/gem "puma", ">= 5.0"/gem "puma", ">= 7.0.3"/' Gemfile
bundle update puma
bin/rails server   # smoke test, ctrl-c
git add Gemfile Gemfile.lock && git commit -m "Phase 3: Upgrade Puma to 7.x for Router 2.0"

# 4. Pin Node
cat > package.json <<'JSON'
{
  "name": "capngown",
  "private": true,
  "engines": {
    "node": "22.x"
  }
}
JSON
git add package.json && git commit -m "Phase 3: Pin Node version via package.json engines"

# 5. Push so far (still on heroku-22 to validate runtime upgrades work first)
git push origin main

# 6. Watch deploy succeed on heroku-22 with the new runtimes
heroku logs --tail -a $APP

# --- Stack switch (separate step, after #6 is stable) ---

# 7. Add nodejs buildpack ahead of ruby
heroku buildpacks:add --index 1 heroku/nodejs -a $APP
heroku buildpacks -a $APP   # verify order

# 8. Set stack
heroku stack:set heroku-24 -a $APP

# 9. Trigger rebuild
git commit --allow-empty -m "Chore: Trigger rebuild on heroku-24 stack"
git push origin main

# 10. Verify
heroku apps:info -a $APP | rg Stack
heroku logs --tail -a $APP

# 11. Smoke test in browser
```

## Rollback

Each step in the runbook is a separate commit, so rollback is `git revert` + push for the offending step. For the stack itself:

```bash
heroku stack:set heroku-22 -a $APP
git commit --allow-empty -m "Chore: Roll back to heroku-22"
git push origin main
```

If Puma 7 misbehaves under load, pin back to 6.x:
```ruby
gem "puma", "~> 6.5"
```

## Open Questions
- Pick exact Ruby patch (`3.3.x`) — recommend latest stable at upgrade time.
- Pick exact Node pin (`22.x` is current LTS; `24.x` matches the buildpack default but moves faster).
- Should we batch all four (bundler/Ruby/Puma/Node) in one PR or stage them? Recommend one PR per step so CI catches regressions cleanly.

## What Was Implemented
_(Filled in as work progresses.)_

## Spec Deviations
_(Add immediately when implementation differs.)_
