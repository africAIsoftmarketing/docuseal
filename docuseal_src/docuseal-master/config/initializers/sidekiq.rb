# frozen_string_literal: true

# Heroku Redis uses self-signed certificates on its `rediss://` (TLS) URLs, so we
# must disable peer verification. This is a no-op for plain `redis://` URLs.
redis_config = {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

Sidekiq.strict_args!

# Sidekiq::Web is only mounted from the web (Puma) dyno, not the worker dyno.
require 'sidekiq/web' if defined?(Puma)

if !ENV['SIDEKIQ_BASIC_AUTH_PASSWORD'].to_s.empty? && defined?(Sidekiq::Web)
  Sidekiq::Web.use(Rack::Auth::Basic) do |_, password|
    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(password),
      Digest::SHA256.hexdigest(ENV.fetch('SIDEKIQ_BASIC_AUTH_PASSWORD'))
    )
  end
end
