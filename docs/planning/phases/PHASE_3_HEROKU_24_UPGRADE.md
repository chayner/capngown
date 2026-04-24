# Phase 3 — Heroku Stack 22 → 24 Upgrade

**Status:** Planned
**Started:** _(not yet)_
**Completed:** _(not yet)_

## Goal
Move `belmont-cap-and-gown` from `heroku-22` to `heroku-24`.

## Context
- Current stack: `heroku-22` (Ubuntu 22.04)
- Target: `heroku-24` (Ubuntu 24.04)
- Stack upgrades affect the OS layer; Ruby 3.2.3 is supported on both. Risk is low for an importmap+CDN-styled app with no native deps beyond `pg` and `nokogiri`.

## Scope

**In:**
- Set stack to `heroku-24`
- Trigger a deploy (rebuild slug on new stack)
- Smoke test

**Out:**
- Ruby version upgrade (separate consideration)
- Bundler upgrade unless required

## Pre-Flight Checks

- [ ] Phase 2 (PG upgrade) complete and stable
- [ ] No traffic / not in distribution week
- [ ] Confirm Ruby 3.2.3 supported on heroku-24 (check Heroku dev center)
- [ ] Capture PG backup as a precaution

## Deliverables

- [ ] `heroku stack:set heroku-24 -a belmont-cap-and-gown`
- [ ] Empty commit + push to trigger rebuild
- [ ] Build succeeds
- [ ] Smoke test passes
- [ ] CHANGELOG updated

## Acceptance Criteria

- [ ] `heroku apps:info` reports `Stack: heroku-24`
- [ ] App responds normally
- [ ] No new errors in logs for 30 min post-deploy

## Runbook

```bash
APP=belmont-cap-and-gown

# 1. Set stack
heroku stack:set heroku-24 -a $APP

# 2. Trigger rebuild (next deploy will use new stack)
git commit --allow-empty -m "Chore: Trigger rebuild on heroku-24 stack"
git push origin main   # CI runs, then deploy

# 3. Verify
heroku apps:info -a $APP | rg Stack
heroku logs --tail -a $APP

# 4. Smoke test in browser
```

## Rollback

```bash
heroku stack:set heroku-22 -a $APP
git commit --allow-empty -m "Chore: Roll back to heroku-22"
git push origin main
```

## Open Questions
- Are there any Heroku add-ons that pin to a specific stack? (None currently identified beyond Postgres, which is decoupled.)

## What Was Implemented
_(Filled in as work progresses.)_

## Spec Deviations
_(Add immediately when implementation differs.)_
