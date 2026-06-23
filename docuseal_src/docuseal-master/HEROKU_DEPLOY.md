# Deploying DocuSeal to Heroku

This repository is adapted for a **Docker-free** Heroku deployment:

```
Heroku App
├── web dyno      → Puma (Rails + REST API + Vue.js front-end)
├── worker dyno   → Sidekiq (emails, webhooks, PDF/image processing)
├── Heroku Postgres (addon)  → database (DATABASE_URL)
├── Heroku Redis (addon)     → Sidekiq broker + cache (REDIS_URL)
└── S3 / R2 / MinIO          → Active Storage (uploads, signed PDFs)
```

## 1. One-command setup (recommended)

```bash
./bin/heroku_setup.sh my-docuseal-app
```

This creates the app, sets the `heroku-24` stack, adds the three buildpacks in
the correct order, provisions Postgres + Redis, sets base config vars, deploys,
and scales a `worker` dyno. Afterwards configure S3 + SMTP (see below).

## 2. Manual setup

```bash
# App + stack
heroku create my-docuseal-app
heroku stack:set heroku-24 -a my-docuseal-app

# Buildpacks — ORDER MATTERS: apt -> nodejs -> ruby
heroku buildpacks:add --index 1 heroku-community/apt -a my-docuseal-app
heroku buildpacks:add heroku/nodejs -a my-docuseal-app
heroku buildpacks:add heroku/ruby -a my-docuseal-app

# Addons
heroku addons:create heroku-postgresql:essential-0 -a my-docuseal-app
heroku addons:create heroku-redis:mini -a my-docuseal-app

# Required config
heroku config:set \
  RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true RAILS_LOG_TO_STDOUT=true \
  SECRET_KEY_BASE="$(openssl rand -hex 64)" FORCE_SSL=true \
  WEB_CONCURRENCY=2 RAILS_MAX_THREADS=5 SIDEKIQ_THREADS=10 \
  -a my-docuseal-app

# Storage (REQUIRED — Heroku disk is ephemeral)
heroku config:set \
  S3_ATTACHMENTS_BUCKET=docuseal-uploads \
  S3_ACCESS_KEY_ID=xxx S3_SECRET_ACCESS_KEY=xxx S3_REGION=us-east-1 \
  -a my-docuseal-app
# For Cloudflare R2 / MinIO also set: S3_ENDPOINT=https://...

# Email (optional but needed to send signing invitations)
heroku config:set \
  SMTP_ADDRESS=smtp.sendgrid.net SMTP_PORT=587 \
  SMTP_USERNAME=apikey SMTP_PASSWORD=SG.xxx SMTP_FROM=noreply@yourdomain.com \
  -a my-docuseal-app

# Deploy
git push heroku main
heroku ps:scale web=1 worker=1 -a my-docuseal-app
```

See [`docs/HEROKU_ENV_VARS.md`](docs/HEROKU_ENV_VARS.md) for the full list of
environment variables.

## 3. What happens on deploy

1. **apt buildpack** installs `libvips` (from `Aptfile`) for image processing.
2. **nodejs buildpack** installs Node + Yarn dependencies.
3. **ruby buildpack** runs `bundle install` and `assets:precompile`
   (Shakapacker compiles the Vue.js / Tailwind / DaisyUI front-end into
   `public/packs`).
4. The **`release` dyno** runs `rails db:migrate` and
   `rails docuseal:download_model` (downloads the ONNX field-detection model
   into `tmp/`; non-fatal if it fails).
5. **web** (Puma) and **worker** (Sidekiq) dynos start.

## 4. One-click deploy

An [`app.json`](app.json) is included for the Heroku Button / Review Apps.

## Notes & constraints

- **Object storage is mandatory** in production — the Heroku filesystem is
  ephemeral. Configure S3 / R2 / MinIO.
- **Postgres connections**: `essential-0` = 20 connections. Keep
  `RAILS_MAX_THREADS + SIDEKIQ_THREADS ≲ 20`.
- **Heroku Redis TLS**: handled via
  `ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }` in
  `config/initializers/sidekiq.rb`.
- **Fonts** (GoNotoKurrent + DancingScript) are vendored under `vendor/fonts/`
  and registered at boot by `config/initializers/fonts.rb`.
- **PDF rendering**: if `libpdfium` is unavailable, DocuSeal falls back to the
  pure-Ruby HexaPDF (already in the Gemfile).
- The `Dockerfile` / `docker-compose.yml` are kept for reference only and are
  not used by Heroku.

## REST API

The DocuSeal REST API is available under `/api/*` (Bearer token via the
`X-Auth-Token` header) and works unchanged on Heroku. If you call it from a
browser on another origin, set `CORS_ORIGINS` (handled by `rack-cors` in
`config/initializers/cors.rb`).
