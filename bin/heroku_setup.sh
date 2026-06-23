#!/bin/bash
set -e

# DocuSeal — initial Heroku setup script.
# Usage: ./bin/heroku_setup.sh [app-name]

APP_NAME="${1:-docuseal-app}"

echo "=== Creating Heroku app: $APP_NAME ==="
heroku create "$APP_NAME"

echo "=== Setting stack to heroku-24 ==="
heroku stack:set heroku-24 -a "$APP_NAME"

echo "=== Adding buildpacks (order matters: apt -> nodejs -> ruby) ==="
heroku buildpacks:clear -a "$APP_NAME" || true
heroku buildpacks:add --index 1 heroku-community/apt -a "$APP_NAME"
heroku buildpacks:add heroku/nodejs -a "$APP_NAME"
heroku buildpacks:add heroku/ruby -a "$APP_NAME"

echo "=== Adding addons (Postgres + Redis) ==="
heroku addons:create heroku-postgresql:essential-0 -a "$APP_NAME"
heroku addons:create heroku-redis:mini -a "$APP_NAME"

echo "=== Configuring base environment variables ==="
heroku config:set \
  RAILS_ENV=production \
  RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  FORCE_SSL=true \
  WEB_CONCURRENCY=2 \
  RAILS_MAX_THREADS=5 \
  SIDEKIQ_THREADS=10 \
  HOST="$APP_NAME.herokuapp.com" \
  -a "$APP_NAME"

echo "=== Deploying ==="
git push heroku main

echo "=== Scaling worker dyno ==="
heroku ps:scale web=1 worker=1 -a "$APP_NAME"

echo "=== Done ==="
echo "URL: https://$APP_NAME.herokuapp.com"
echo ""
echo "Remember to configure (heroku config:set ...):"
echo "  - S3_ATTACHMENTS_BUCKET, S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY, S3_REGION"
echo "    (and S3_ENDPOINT for Cloudflare R2 / MinIO)"
echo "  - SMTP_ADDRESS, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD, SMTP_FROM"
