# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Local Development (Cap & Gown)

### Run the app

```bash
bin/dev
```

Default local URL:

```text
https://dev.bucapandgown.com:3002
```

### Host mapping

Add this line to `/etc/hosts`:

```text
127.0.0.1 dev.bucapandgown.com
```

### Local HTTPS certificates

This project is configured to use local TLS in development with `mkcert`.

```bash
mkcert -install
mkcert -cert-file config/ssl/dev.bucapandgown.com.pem \
	-key-file config/ssl/dev.bucapandgown.com-key.pem \
	dev.bucapandgown.com localhost 127.0.0.1 ::1
```

The key and cert are gitignored in `config/ssl/`.

### PostgreSQL version check (local)

Verify the server version Rails is connected to:

```bash
bundle exec rails runner "puts ActiveRecord::Base.connection.select_value('SHOW server_version')"
```
