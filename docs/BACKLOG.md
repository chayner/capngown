# Backlog

Deferred work, known debt, and ideas for Cap & Gown. Items here are not on a phase yet.

When an item is picked up, move it to a phase spec and remove from this list (or check it off and leave a "moved to Phase N.X" note).

---

## Infrastructure / Setup

- [ ] **GitHub Actions CI** — Add a workflow to run `bin/rails test` on every push and PR. Block deploy until green.
- [x] ~~**Move from Railway artifacts to Heroku**~~ — Done in Phase 1. `rails_12factor` removed, `database.yml` cleaned, `Procfile` added.
- [ ] **Test coverage** — The current test suite is essentially empty. Add baseline model + controller tests as a first sub-phase.
- [ ] **Strong params on `GraduatesController#update`** — Currently reads `params[:graduate][:height]` directly. Consider permit-allowlist.
- [ ] **Audit `config/environments/production.rb` hosts list** — Several legacy domains (`infinite-meadow-09480.herokuapp.com`, `belmontalum.chip.fyi`, `capngown.bualum.co`). Verify which are still in use; remove the rest.
- [x] ~~**Runtime modernization (Phase 3)**~~ — Completed in Phase 3: stack `heroku-24`, Ruby `3.3.10`, Bundler `2.7.2`, Puma `8.0.0`, Node pin `22.x`.
- [ ] **Phase 3 follow-up: Ruby patch bump** — Upgrade Ruby from `3.3.10` to `3.3.11` to clear Heroku "newer patch available" warning.
- [ ] **Phase 3 follow-up: final post-deploy validation** — Run full 30-minute `heroku logs --tail` watch and full manual flow smoke test (lookup, check-in, print queue, stats), then close remaining acceptance checkboxes.

## Auth / Security

- [ ] **Devise + role-based access** — Add `Volunteer`, `Coordinator`, `Admin` roles per the planned hierarchy in `CLAUDE.md`. Until then, every action is publicly reachable.
- [ ] **Rate limiting** — Once auth lands, consider rack-attack on lookup endpoints.

## Features

- [ ] _(add feature ideas here)_

## Tech Debt

- [ ] **`brags.buid` index** — `cords` has an index on `[buid, cord_type]` but `brags` has no index. If brag lookups become hot, add `add_index :brags, :buid`.
- [ ] **`pages_controller` / `pages_helper` purpose unclear** — audit whether the `welcome` route and pages controller are still used; remove if dead code.
- [ ] **`vendor/javascript/`** — verify pinned files match what's actually imported.

## Documentation

- [ ] Fill in real content for the `docs/ai-context/AI_0*` stubs as the app's state is documented.
- [ ] Establish first phase spec under `docs/planning/phases/`.

---

_Last reviewed: when this file was created._
