# AI_03 — User Roles and Permissions

## Current State

**No authentication exists.** Every controller action is publicly reachable. Treat the app as open until Devise is added (Phase 4).

## Future-State Role Hierarchy (Planned — Phase 4)

When auth lands, the planned hierarchy is **two roles**:

| Role | What They Can Do | Guard Method |
|------|------------------|--------------|
| **Volunteer** | Look up graduates, check in, mark printed, bulk print/clear, stats dashboard | `before_action :authenticate_user!` |
| **Admin** | Everything Volunteer can do, plus user management and file imports | `before_action :require_admin!` |

`current_user.volunteer?` returns `true` for both volunteers and admins (admin is a superset).

## Action → Required Role (Planned)

| Action | Min Role |
|--------|----------|
| `start`, `list`, `show` (graduate lookup) | Volunteer |
| `checkin`, `print` (single graduate) | Volunteer |
| `to_print` (print queue view) | Volunteer |
| `update` (height edit) | Volunteer |
| `show_bulk`, `bulk_print` | Volunteer |
| `stats` | Volunteer |
| User management (Phase 5) | Admin |
| File imports — graduates / brags / cords (Phase 5) | Admin |

## Notes

- The role enum lives on `User` (Devise model) and uses Rails enums.
- Two roles is intentionally simple. Re-introduce a middle "Coordinator" role only if a real need surfaces.
- Anonymous users (not logged in) get redirected to login. There is no public read.
- An "Admin" UI lives under `/admin/*` and is only reachable by admins.
