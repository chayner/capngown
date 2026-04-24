# Admin User Management

> Cap & Gown is **invite-only**. There is no public sign-up. Admins create all accounts, including other admin accounts, via rake tasks.

## Local development

Open a terminal at the project root.

### Create the first admin

```bash
bin/rails admin:create EMAIL=you@belmont.edu PASSWORD=changeme8
```

Password must be 8 characters minimum.

### Create a volunteer

```bash
bin/rails admin:invite_volunteer EMAIL=v@belmont.edu PASSWORD=somepass8
```

### Reset a user's password (admin or volunteer)

```bash
bin/rails admin:reset_password EMAIL=v@belmont.edu PASSWORD=newpass8
```

### Promote an existing user to admin

```bash
bin/rails admin:promote EMAIL=v@belmont.edu
```

## Heroku (production)

Use `heroku run` to execute the same commands on the live dyno:

```bash
heroku run -a belmont-cap-and-gown bin/rails admin:create EMAIL=you@belmont.edu PASSWORD=changeme8
heroku run -a belmont-cap-and-gown bin/rails admin:invite_volunteer EMAIL=v@belmont.edu PASSWORD=somepass8
heroku run -a belmont-cap-and-gown bin/rails admin:reset_password EMAIL=v@belmont.edu PASSWORD=newpass8
heroku run -a belmont-cap-and-gown bin/rails admin:promote EMAIL=v@belmont.edu
```

## Bootstrap order for a fresh deploy

1. Deploy.
2. `heroku run bin/rails admin:create EMAIL=... PASSWORD=...` — creates first admin.
3. Sign in.
4. From the same admin account, run `admin:invite_volunteer` for each volunteer.
5. Share credentials with each volunteer over a secure channel.

## Why no email-based password reset?

Email password resets are deferred (see `docs/BACKLOG.md`). Until they exist, the `admin:reset_password` rake task is the only path to recover a forgotten password. An admin must run the command on behalf of the user.
