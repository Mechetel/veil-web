require_relative "boot"

# Bare (non-Docker) dev/test: load the same dev secret-envs that docker compose
# injects via `env_file:` and Kamal injects via `.kamal/secrets`. Runs before
# Rails reads config/database.yml and config/veil.yml. Never overwrites real ENV
# (so docker compose / Kamal values win), and is a no-op in production.
unless ENV["RAILS_ENV"] == "production"
  begin
    require "dotenv"
    Dotenv.load(File.expand_path("../docker/secret-envs/veil-core.env", __dir__))
  rescue LoadError
    # dotenv is dev/test-only; ignore if absent.
  end
end

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VeilWeb
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Europe/Kyiv"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
