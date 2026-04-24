---
name: patterns
description: Code patterns, conventions, and quality standards for Cap & Gown. Use when creating new files, services, or components.
disable-model-invocation: false
---

# Patterns & Conventions

## Core Principle: Patterns Before Invention

Always assume an existing pattern should be followed before creating something new:

1. **Before creating a new file** — Check if similar files exist and follow their naming/structure
2. **Before adding a new function** — Search for existing utilities (especially in `lib/`)
3. **Before designing UI** — Look at existing views (`app/views/graduates/`) for component patterns
4. **Before adding a filter/dropdown** — Check existing Stimulus controllers in `app/javascript/controllers/`
5. **Before naming anything** — Find 2-3 examples of similar naming in the codebase

## Cap & Gown Established Patterns

### Models
- **Graduate** uses `buid` as primary key. Any new model that joins to graduates uses `primary_key: "buid", foreign_key: "buid"` (see `Graduate#has_many :brags`).
- **Translators** for short-code → human-readable mapping live in `lib/` as plain Ruby modules with class methods (see `CollegeCodeTranslator`).

### Controllers
- RESTful where possible (`resources :graduates, except: :index, param: :buid`).
- `before_action :set_graduate` to load by `buid`.
- Filters on index/list actions read from `params[:fullname]`, `params[:college]`, etc., and chain `where` clauses guarded by `present?` (see `GraduatesController#list`).
- "State flag" actions (`checkin`, `print`) accept a `?param=clear` query to set the flag back to `nil`.

### Views
- Partials live alongside their controller's views (e.g., `app/views/graduates/_search.html.erb`).
- Picnic CSS classes for styling (`button`, `success`, `dangerous`, `pseudo`).
- Material Symbols icons via the Google Fonts link in `application.html.erb`.

### Lib / Translators
- File-per-concept in `lib/` (one translator per file).
- Module-with-class-methods pattern: `CollegeCodeTranslator.translate_full(code)`.

## Proactive Quality Guardianship

| Situation | Action |
|-----------|--------|
| You notice an inconsistency | **Call it out** — don't silently perpetuate it |
| User's request would create duplication | **Recommend the existing pattern** |
| A proposed approach conflicts with codebase conventions | **Explain the conflict and suggest alternatives** |
| You find technical debt while working | **Note it** — add to `docs/BACKLOG.md` or mention in pause |
| Documentation is outdated | **Update it** as part of your work |

## Pattern Discovery Workflow

Before implementing, ask:
1. "Is there already a [translator/controller action/partial] that does this?"
2. "What's the naming pattern for [this type of thing]?"
3. "How does the existing [similar feature] handle this?"

```bash
# Search for existing patterns
rg "class.*Translator" lib/
rg "def list\|def show_bulk" app/controllers/
rg "data-controller" app/views/
```

## Complete Every Integration (Anti-Orphan Rule)

When creating any new file (partial, controller, service, helper, etc.):
1. **Create the file**
2. **Integrate it** — render the partial, call the service, use the helper
3. **Verify it renders** — check in browser or confirm via test
4. **If integration is deferred** — explicitly note it and add to `docs/BACKLOG.md`

**Checklist before moving on from any new file:**
- [ ] Is this file actually used somewhere?
- [ ] Have I verified it renders/runs correctly?
- [ ] If deferred, have I documented why?

## Spec Deviation Rule

When implementation would differ from the spec document:
1. **STOP before implementing**
2. **Explain the deviation** — Why is the spec approach problematic?
3. **Propose alternatives**
4. **Get explicit approval**
5. **Update the spec**

## Frontend Patterns

### Picnic CSS (Not Tailwind)
- Use Picnic's semantic classes: `button`, `success`, `warning`, `error`, `dangerous`, `pseudo`.
- Add custom overrides in `app/assets/stylesheets/`.
- For dynamic state classes, use a Ruby helper that returns a literal class string (no string interpolation that JIT-purgers can't see — though Picnic doesn't JIT, this is still a good habit).

### Stimulus Controllers
- One controller per behavior. File path: `app/javascript/controllers/[name]_controller.js`.
- Register in `app/javascript/controllers/index.js`.
- Connect via `data-controller="name"` on the element; events via `data-action="event->name#method"`.

### Importmap
```bash
bin/importmap pin some-package    # add JS dep
```
Update `config/importmap.rb` and import in your controller file.

## Service-ish Code (Currently Lives in `lib/`)

The app does not yet have an `app/services/` directory. When the first true service object is needed:
1. Create `app/services/`
2. Use a plain Ruby class with `initialize(...)` and a public `call` method
3. Document the new directory in this skill and in `CLAUDE.md`

Until then, prefer adding new domain helpers as modules in `lib/` (matching the translator pattern).

## When to Break from Patterns

1. **Pause and explain** why the existing pattern doesn't fit
2. **Propose the new pattern** with rationale
3. **Get explicit approval** before proceeding
4. **Document the new pattern** so future work can follow it
