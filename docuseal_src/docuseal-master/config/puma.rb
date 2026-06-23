# frozen_string_literal: true

# Puma configuration for Heroku.
#
# Heroku injects all environment variables natively (no dotenv needed in production)
# and provides Redis/Postgres as external addons. Sidekiq runs in its own `worker`
# dyno, so the embedded Sidekiq and forked Redis plugins are NOT loaded here.

# Threads: keep a predictable, fixed-size pool. The Active Record connection pool
# in config/database.yml is sized off RAILS_MAX_THREADS.
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

# Allow long worker timeouts only in development.
worker_timeout 3600 if ENV.fetch('RAILS_ENV', 'development') == 'development'

# Heroku routes traffic to the port provided via $PORT.
port ENV.fetch('PORT', 3000)

environment ENV.fetch('RAILS_ENV', 'development')

# Heroku manages the process; no pidfile required.
@options[:pidfile] = false

# Number of Puma workers (forked processes). Heroku sets WEB_CONCURRENCY
# automatically on Performance dynos; default to 2 otherwise.
workers ENV.fetch('WEB_CONCURRENCY', 2)

# Preload the app to take advantage of Copy-On-Write and reduce per-worker memory.
preload_app!

# Reconnect Active Record in each forked worker.
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
end
