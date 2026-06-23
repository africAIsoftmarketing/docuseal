# DocuSeal — Heroku Environment Variables

This document lists every environment variable used by the Heroku deployment of
DocuSeal. Set them with `heroku config:set KEY=value -a <app>` (or via the
Heroku Dashboard → Settings → Config Vars).

## === Required ===

| Variable | Description |
|----------|-------------|
| `SECRET_KEY_BASE` | Rails secret. Generate with `rails secret` or `openssl rand -hex 64`. Also used to derive Active Record encryption keys. |
| `RAILS_ENV` | Must be `production`. |
| `RAILS_SERVE_STATIC_FILES` | `true` — Heroku has no Nginx in front, Rails serves the compiled assets. |
| `RAILS_LOG_TO_STDOUT` | `true` — logs go to STDOUT (Heroku log drain). |

## === Database (auto-provisioned by the Heroku Postgres addon) ===

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Auto-set by `heroku-postgresql`. Used directly in `config/database.yml`. |

> Connection pool note: `essential-0` allows **20 connections**. With
> `RAILS_MAX_THREADS=5` the web pool is `5 + 5 = 10`, and the worker dyno uses
> `SIDEKIQ_THREADS` connections. Keep `RAILS_MAX_THREADS + SIDEKIQ_THREADS ≲ 20`.

## === Redis (auto-provisioned by the Heroku Redis addon) ===

| Variable | Description |
|----------|-------------|
| `REDIS_URL` | Auto-set by `heroku-redis`. Sidekiq broker + cache. TLS (`rediss://`) is handled via `ssl_params: { verify_mode: VERIFY_NONE }`. |

## === Storage — S3 / R2 / MinIO (required in production) ===

Heroku's filesystem is **ephemeral** — disk storage is NOT persistent. You MUST
configure object storage.

| Variable | Description |
|----------|-------------|
| `S3_ATTACHMENTS_BUCKET` | Bucket name. Presence of this var switches Active Storage to `:aws_s3`. |
| `S3_ACCESS_KEY_ID` | Access key (falls back to `AWS_ACCESS_KEY_ID`). |
| `S3_SECRET_ACCESS_KEY` | Secret key (falls back to `AWS_SECRET_ACCESS_KEY`). |
| `S3_REGION` | Region, default `us-east-1` (falls back to `AWS_REGION`). |
| `S3_ENDPOINT` | *(optional)* Custom endpoint for Cloudflare R2 / MinIO. When set, `force_path_style` is enabled. |
| `S3_FORCE_PATH_STYLE` | *(optional)* `true`/`false`, defaults to `true` when an endpoint is set. |

## === Email (SMTP) ===

Email is sent only when `SMTP_ADDRESS` is present.

| Variable | Description |
|----------|-------------|
| `SMTP_ADDRESS` | e.g. `smtp.sendgrid.net` |
| `SMTP_PORT` | e.g. `587` |
| `SMTP_USERNAME` | e.g. `apikey` (SendGrid) |
| `SMTP_PASSWORD` | SMTP password / API key |
| `SMTP_DOMAIN` | *(optional)* HELO domain |
| `SMTP_FROM` | Default "from" address, e.g. `noreply@yourdomain.com` |
| `SMTP_AUTHENTICATION` | *(optional)* `plain` (default), `login`, `cram_md5` |
| `SMTP_ENABLE_STARTTLS` | *(optional)* `true`/`false` (default `true`) |
| `SMTP_ENABLE_SSL` | *(optional)* `true`/`false` |
| `SMTP_ENABLE_TLS` | *(optional)* `true`/`false` |
| `SMTP_SSL_VERIFY` | *(optional)* set `false` to disable certificate verification |

## === Optional / Tuning ===

| Variable | Description |
|----------|-------------|
| `HOST` | Public hostname, e.g. `your-app.herokuapp.com`. |
| `FORCE_SSL` | `true` enables `force_ssl` + `assume_ssl` (recommended on Heroku). |
| `WEB_CONCURRENCY` | Number of Puma workers (default `2`). |
| `RAILS_MAX_THREADS` | Puma/AR thread pool size (default `5`). |
| `RAILS_MIN_THREADS` | *(optional)* defaults to `RAILS_MAX_THREADS`. |
| `SIDEKIQ_THREADS` | Sidekiq concurrency (default `10`). |
| `SIDEKIQ_BASIC_AUTH_PASSWORD` | Password for the `/sidekiq` web UI (basic auth). |
| `RAILS_LOG_LEVEL` | `info` (default), `debug`, `warn`, etc. |
| `CORS_ORIGINS` | Comma-separated allowed origins for `/api/*` (default `*`). |
| `ONNX_MODEL_URL` | *(optional)* Override URL for the field-detection ONNX model. |
| `ACTIVE_STORAGE_PUBLIC` | `true` to serve attachments publicly (default proxied/private). |
| `PRESIGNED_URLS_EXPIRE_MINUTES` | Expiry for signed storage URLs (default `240`). |
| `ENCRYPTION_SECRET` | *(optional)* Override the Active Record encryption secret (defaults to a hash of `SECRET_KEY_BASE`). |

## Quick reference — set everything at once

```bash
heroku config:set \
  RAILS_ENV=production \
  RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  FORCE_SSL=true \
  WEB_CONCURRENCY=2 \
  RAILS_MAX_THREADS=5 \
  SIDEKIQ_THREADS=10 \
  HOST=your-app.herokuapp.com \
  S3_ATTACHMENTS_BUCKET=docuseal-uploads \
  S3_ACCESS_KEY_ID=xxx \
  S3_SECRET_ACCESS_KEY=xxx \
  S3_REGION=us-east-1 \
  SMTP_ADDRESS=smtp.sendgrid.net \
  SMTP_PORT=587 \
  SMTP_USERNAME=apikey \
  SMTP_PASSWORD=SG.xxxxx \
  SMTP_FROM=noreply@yourdomain.com \
  -a your-app
```
