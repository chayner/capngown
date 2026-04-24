# AI_03 — User Roles and Permissions

## Current State (Phase 4 complete)

Auth is **enforced site-wide** via Devise. Every controller action requires `authenticate_user!`. Two roles exist:

| Role | What They Can Do | Guard |
|------|------------------|-------|
| **Volunteer** | Look up graduates, check in, mark printed, bulk print/clear, stats dashboard | `before_action :authenticate_user!` (default in `ApplicationController`) |
| **Admin** | Everything Volunteer can do, plus user management (rake tasks today, UI in Phase 5) | `before_action :require_admin!` |

`current_user.volunteer?` returns `true` for both volunteers and admins (admin is a superset). `current_user.admin?` is true only for admins.

Account creation is **invite-only** — there is no public sign-up. Admins create accounts via `bin/rails admin:create` / `admin:invite_volunteer`. Password reset is also admin-driven via `bin/rails admin:reset_password`. See [docs/development/ADMIN_USER_MANAGEMENT.md](../development/ADMIN_USER_MANAGEMENT.md).

## Action → Required Role

| Action | Min Role |
|--------|----------|
| `start`, `list`, `show` (graduate lookup) | Volunteer |
| `checkin`, `print` (single graduate) | Volunteer |
| `to_print` (print queue view) | Volunteer |
| `update` (height edit) | Volunteer |
| `show_bulk`, `bulk_print` | Volunteer |
| `stats` | Volunteer |
| User management UI (Phase 5) | Admin |
| File imports — graduates / brags / cords (Phase 5) | Admin |

## Implementation Notes

- The role enum lives on `User` (`enum role: { volunteer: 0, admin: 1 }`) backed by an indexed integer column.
- `User#volunteer?` is overridden so admins also report `true` (hierarchy).
- Devise modules in use: `:database_authenticatable`, `:recoverable`, `:rememberable`, `:validatable`. `:registerable` is intentionally **not** included.
- Routes: `devise_for :users, skip: [:registrations]`. The `:passwords` routes exist only because Devise references `new_user_password_path` internally on failed sign-in flash; the UI never links to them.
- Min password length: 8 (configured in `config/initializers/devise.rb`).
- Sessions: standard Devise per-browser cookie; "Remember me" supported.
- Two roles is intentionally simple. Re-introduce a middle "Coordinator" role only if a real need surfaces.
- Audit log of who-did-what is in [docs/BACKLOG.md](../BACKLOG.md).
