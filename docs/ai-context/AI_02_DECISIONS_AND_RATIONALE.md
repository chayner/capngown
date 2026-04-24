# AI_02 — Decisions and Rationale

Document significant architectural and product decisions here as they're made. Include date, decision, alternatives considered, and rationale.

---

## Format

```
## YYYY-MM-DD — [Short title]

**Decision:** [What was decided]
**Alternatives considered:** [What else was on the table]
**Rationale:** [Why this won]
**Consequences:** [What this commits us to]
```

---

## Pre-AI-Era Decisions (Reverse-Engineered)

### `Graduate` primary key is `buid` (string), not a numeric `id`

**Decision:** Use Belmont's BUID as the graduate primary key.
**Rationale:** BUID is the canonical identifier across all Belmont systems. Lookups always come in by BUID. Avoids needing a join table or secondary lookup.
**Consequences:** Routes use `param: :buid`. Cannot use `Graduate.find(numeric_id)`. Every join uses `primary_key: "buid"`.

### `Cord` table has no `id` column

**Decision:** Composite identity `[buid, cord_type]` with a unique index, no surrogate `id`.
**Rationale:** Cords are a pure many-to-many fact ("this graduate gets this kind of cord"). No need to reference an individual cord row by ID.
**Consequences:** `cord.id` returns `nil`. Don't build features that need to link to or update an individual cord row.

### Picnic CSS instead of Tailwind / Bootstrap

**Decision:** Picnic via CDN.
**Rationale:** Tiny dependency footprint, zero build step, semantic-class approach matches Rails ERB nicely.
**Consequences:** No utility classes. Custom design needs SCSS overrides. JIT-purger gotchas don't apply, but neither do the design conveniences of TailwindUI.

### Importmap instead of esbuild/webpack

**Decision:** Use Rails' importmap-rails for JS dependencies.
**Rationale:** Keeps the asset pipeline simple, no Node toolchain.
**Consequences:** Use `bin/importmap pin` for new JS deps. Pinned files land in `vendor/javascript/`.

### No timestamps on legacy tables

**Decision:** `graduates`, `brags`, `cords` do not have `created_at` / `updated_at`.
**Rationale:** Records are imported in bulk from a roster source; "when was this row created" isn't meaningful — the roster's load date is what matters.
**Consequences:** `.order(:created_at)` will raise. Use `checked_in` and `printed` as the available time-based markers.

---

## Recent Decisions

_(Add new decisions above this line as they're made.)_
