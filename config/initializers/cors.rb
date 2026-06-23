# frozen_string_literal: true

# Cross-Origin Resource Sharing (CORS) for the DocuSeal REST API.
#
# Enabled only when the `rack-cors` gem is available. Set CORS_ORIGINS to a
# comma-separated list of allowed origins (defaults to '*' for open API access).
if defined?(Rack::Cors)
  Rails.application.config.middleware.insert_before(0, Rack::Cors) do
    allow do
      origins(ENV.fetch('CORS_ORIGINS', '*').split(',').map(&:strip))

      resource '/api/*',
               headers: :any,
               methods: %i[get post put patch delete options head],
               expose: ['X-Total-Count']
    end
  end
end
