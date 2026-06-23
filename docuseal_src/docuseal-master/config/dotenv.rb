# frozen_string_literal: true

# Heroku provides all environment variables natively, so dotenv is only used
# for local development and test. No Docker-specific bootstrapping (UID changes,
# forked Redis, generated docuseal.env) is needed on Heroku.
unless ENV['RAILS_ENV'] == 'production'
  require 'dotenv'
  Dotenv.load
end
