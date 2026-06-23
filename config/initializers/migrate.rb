# frozen_string_literal: true

# Run pending migrations on boot in production, EXCEPT:
#   - when explicitly disabled via RUN_MIGRATIONS=false (recommended on Heroku,
#     where the `release` phase runs `rails db:migrate`);
#   - when no database is configured yet (e.g. during `assets:precompile` at
#     build time on Heroku, where DATABASE_URL is not injected).
#
# Any connection error is rescued so the asset build / boot never crashes.
Rails.configuration.to_prepare do
  run_migrations = ENV['RAILS_ENV'] == 'production' &&
                   ENV['RUN_MIGRATIONS'] != 'false' &&
                   ENV['DATABASE_URL'].present?

  if run_migrations
    begin
      ActiveRecord::Tasks::DatabaseTasks.migrate
    rescue StandardError => e
      Rails.logger.warn("[migrate] Skipped boot-time migration: #{e.class}: #{e.message}")
    end
  end
end
