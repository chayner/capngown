---
name: performance
description: Memory optimization and performance patterns for Heroku-hosted Cap & Gown. Use when working on performance issues or building data-heavy features.
disable-model-invocation: false
---

# Performance & Memory (Heroku)

**Context:** Cap & Gown will run on Heroku with memory-constrained dynos. The dataset is bounded but not small — a single graduating class can be several thousand records, plus brags and cords. These patterns prevent R14 (memory quota) and H12 (timeout) errors.

## Memory-Safe Coding Patterns

| Pattern | Why |
|---------|-----|
| Avoid `.to_a` on large queries | Loads entire dataset into memory |
| Batch processing (50 records) | Limits memory per iteration |
| Use `.find_each` for full-table iteration | Default batch size 1000 |
| Limit processing to 1,000 max | Prevents runaway queries |
| Cache expensive calculations | The stats dashboard recomputes a lot — cache it |
| Pass only rendered data to views | Don't send 5,000 rows when view shows 25 |

## Cap & Gown Specific Hot Spots

### Stats Dashboard (`GraduatesController#stats`)
- Currently runs ~15+ separate `COUNT` queries on every page load.
- If the page becomes slow:
  1. Group counts into single `GROUP BY` queries where possible
  2. Add a 1-minute fragment cache around per-college blocks
  3. Consider denormalized counters if it ever becomes a real problem

### Print Queue (`GraduatesController#to_print`, `#get_print_html`)
- Renders every checked-in-but-unprinted graduate.
- If the queue grows large, paginate or cap at N records.
- `get_print_html` returns a raw string — keep it lightweight.

### List/Search (`GraduatesController#list`)
- Already does the right thing with `.includes(:brags)` to avoid N+1 on brag display.
- Cord preload uses `.index_by(&:buid)` — good. Don't regress this to per-row `graduate.cords` calls.

## Memory Leak Prevention

### 1. Don't `.to_a` Big Queries
```ruby
# DANGEROUS
all_grads = Graduate.where(checked_in: nil).to_a   # could be thousands

# SAFE
Graduate.where(checked_in: nil).find_each(batch_size: 100) do |g|
  # process one at a time
end
```

### 2. Keep Views Lightweight
```ruby
# HEAVY: Pass full dataset to view
@graduates = Graduate.all   # 5000 records

# LIGHT: Pass only what the view renders
@graduates = Graduate.where(...).limit(50)
```

### 3. Release Heavy Locals After Use
```ruby
def stats
  big_query_result = expensive_calc
  @summary = summarize(big_query_result)
  big_query_result = nil   # free reference before view renders
end
```

## Heroku Configuration

```ruby
# config/puma.rb
workers 1          # Single worker
threads 3, 3       # Fixed thread count
```

## Database Performance
- `graduates.buid` is the PK (already indexed)
- `cords` has a composite unique index on `[buid, cord_type]`
- `brags.buid` is **not** indexed — if brag lookups become hot, add an index
- Use `.includes()` to prevent N+1 (search for any view that does `graduate.brags.count` in a loop)

```bash
# Find potential N+1s
rg "\.brags\." app/views/
rg "\.cords\." app/views/
```

## Timeout Protection
- Heroku H12 fires at 30s. Aim for sub-15s response time.
- Long-running operations (CSV imports, bulk recalc) belong in a background job — not yet wired up; would need Sidekiq.

## Monitoring Commands

```bash
heroku logs --tail | rg "(Allocations|ActiveRecord|Completed)"
heroku ps                 # see dyno memory
heroku pg:diagnose        # check DB health
```

## Memory Leak Checklist (New Features)
- [ ] Does it `.to_a` a large query? → Switch to `.find_each`
- [ ] Does it pass data to views? → Pass only what's rendered
- [ ] Could it be triggered by a user iterating quickly? → Add a rate limit or cache
- [ ] Does it create temp files? → Add cleanup
