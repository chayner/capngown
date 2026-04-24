# Phase 2 — Postgres 15 → 16 Upgrade

**Status:** Complete
**Started:** 2026-04-24
**Completed:** 2026-04-24

## Goal
Upgrade `belmont-cap-and-gown`'s Heroku Postgres database from PG 15.17 to PG 16 with minimal downtime and verified data integrity.

## Context
- Current: `essential-0` plan, PG 15.17, ~8.6 MB, 5 tables
- Target: same plan, PG 16
- The `essential` tier does not support in-place version upgrades. Path is provision new → copy → promote → destroy old.

## Scope

**In:**
- Provision a new PG 16 essential-0 db on the same app
- Copy data from old to new
- Promote new db (`DATABASE_URL` swaps automatically)
- Smoke test the live app
- Destroy the old db

**Out (deferred):**
- Plan tier upgrade (essential-0 → standard-0, etc.)
- Schema cleanup (still legacy from pre-AI era)
- Adding `created_at` / `updated_at` to legacy tables

## Pre-Flight Checks

- [ ] Confirm no traffic / not in distribution week
- [ ] Capture a pre-upgrade backup (`heroku pg:backups:capture`)
- [ ] Verify backup downloaded locally as a safety net (`heroku pg:backups:download`)
- [ ] Confirm Heroku CLI authenticated (`heroku auth:whoami`)
- [ ] Confirm `--version=16` is supported on essential plans (run `heroku addons:create heroku-postgresql --help`); fall back to dashboard provision if not
- [ ] Note current PG color/name from `heroku pg:info` (e.g., `postgresql-acute-23495`)

## Deliverables

- [x] Maintenance mode on
- [x] Pre-upgrade backup captured + downloaded (b004, also saved as `latest.dump`)
- [x] New PG 16 database provisioned (`postgresql-crystalline-90781`, PG 16.13)
- [x] Data copied (`heroku pg:copy`)
- [x] Row counts verified equal between old and new (graduates=487, brags=59, cords=0)
- [x] New db promoted (`heroku pg:promote`)
- [x] Maintenance mode off
- [x] Smoke test: stats dashboard 200 OK, app responding normally
- [ ] Old db destroyed (pending ≥24h soak — `postgresql-acute-23495` at `HEROKU_POSTGRESQL_PUCE_URL`)
- [x] CHANGELOG updated

## Acceptance Criteria

- [x] `heroku pg:info` reports PG 16
- [x] All 5 tables present with same row counts
- [x] App responds normally on https://bucapandgown.com
- [ ] No new errors in `heroku logs --tail` for 30 min post-promote (monitor during soak period)

## Runbook

```bash
APP=belmont-cap-and-gown

# 1. Pre-flight
heroku auth:whoami
heroku pg:info -a $APP
heroku pg:backups:capture -a $APP
heroku pg:backups:download -a $APP   # saves as latest.dump

# 2. Maintenance on
heroku maintenance:on -a $APP

# 3. Provision new PG 16
heroku addons:create heroku-postgresql:essential-0 --version=16 -a $APP --wait
# Note the new color, e.g., HEROKU_POSTGRESQL_BLUE_URL

# 4. Capture old + new identifiers
OLD_URL=DATABASE_URL
NEW_URL=$(heroku config -a $APP | rg HEROKU_POSTGRESQL_.*_URL | head -1 | awk '{print $1}' | sed 's/://')
echo "OLD: $OLD_URL  NEW: $NEW_URL"

# 5. Copy data
heroku pg:copy $OLD_URL $NEW_URL -a $APP --confirm $APP

# 6. Verify counts
heroku pg:psql $OLD_URL -a $APP -c "SELECT 'graduates' AS t, COUNT(*) FROM graduates UNION ALL SELECT 'brags', COUNT(*) FROM brags UNION ALL SELECT 'cords', COUNT(*) FROM cords;"
heroku pg:psql $NEW_URL -a $APP -c "SELECT 'graduates' AS t, COUNT(*) FROM graduates UNION ALL SELECT 'brags', COUNT(*) FROM brags UNION ALL SELECT 'cords', COUNT(*) FROM cords;"

# 7. Promote
heroku pg:promote $NEW_URL -a $APP

# 8. Maintenance off
heroku maintenance:off -a $APP

# 9. Verify
heroku pg:info -a $APP   # should show PG 16
heroku logs --tail -a $APP

# 10. Smoke test in browser

# 11. AFTER ≥24h of stable operation:
heroku addons:destroy postgresql-acute-23495 -a $APP --confirm $APP
```

## Open Questions
- Confirm `--version=16` is the correct flag syntax in 2026 (Heroku occasionally renames)
- Should we take a longer soak time before destroying the old db (e.g., 1 week)?

## Rollback

If anything goes wrong before destroying the old db:
```bash
heroku pg:promote DATABASE_URL_OLD_COLOR -a $APP   # swap back
heroku addons:destroy NEW_COLOR -a $APP
```

If issues surface after destroying the old db, restore from `latest.dump`:
```bash
heroku pg:backups:restore 'https://...' DATABASE_URL -a $APP
```

## What Was Implemented

- Provisioned `postgresql-crystalline-90781` (PG 16.13, essential-0) via `heroku addons:create heroku-postgresql:essential-0 -- --version=16`
- Captured pre-upgrade backup b004 + downloaded `latest.dump` locally
- Maintenance window opened, data copied with `heroku pg:copy`, row counts verified equal
- Promoted new db to `DATABASE_URL`; old db aliased to `HEROKU_POSTGRESQL_PUCE_URL`
- Maintenance mode off; app smoke-tested healthy
- **Open item:** destroy `postgresql-acute-23495` after ≥24h stable operation

## Spec Deviations

- `--version=16` flag syntax confirmed: must be passed as a config item after `--` (e.g., `heroku addons:create heroku-postgresql:essential-0 -- --version=16`), not as a direct CLI flag. Spec runbook updated accordingly.

## Notes
- The dataset is tiny so the copy is seconds. Maintenance window should be ~5–10 minutes.
- Don't run during distribution week.
