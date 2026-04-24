# AI_01 — Scope and Non-Goals

## In Scope

- Graduate lookup (BUID and name search)
- Check-in workflow with optional height capture
- Sticker print queue (single + bulk)
- Brag card display alongside graduate records
- Honor cord display alongside graduate records
- Stats dashboard for distribution progress
- _(planned)_ Devise auth with Volunteer/Coordinator/Admin roles
- _(planned)_ Heroku deployment with CI

## Explicitly Out of Scope

- **Public-facing graduate self-service** — graduates don't log in or use this app directly.
- **Payment / e-commerce** — no fees collected, no transactions.
- **Long-term records** — this is a distribution-day tool. Roster data is reloaded each season.
- **Mobile native apps** — responsive web only.
- **Offline mode** — assumes a working network in the distribution venue.
- **Custom regalia ordering** — packets are pre-assembled; this app routes them, not creates them.

## Stretch Goals (Not Promised)

- Background jobs (Sidekiq) for bulk imports
- Audit log of who checked which graduate in (depends on auth)
- CSV export of distribution stats

## Anti-Features

- No notifications/email to graduates from this app.
- No social sharing.
- No analytics tracking of individual user behavior.
