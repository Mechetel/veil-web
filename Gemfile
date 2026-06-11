source "https://rubygems.org"

ruby "3.4.9"

gem "rails", "~> 8.1", ">= 8.1.3"
gem "propshaft", "~> 1.3", ">= 1.3.2"
gem "pg", "~> 1.6", ">= 1.6.2"
gem "puma", "~> 8.0", ">= 8.0.2"
gem "importmap-rails", "~> 2.2", ">= 2.2.3"
gem "turbo-rails", "~> 2.0", ">= 2.0.23"
gem "stimulus-rails", "~> 1.3", ">= 1.3.4"
gem "jbuilder", "~> 2.15", ">= 2.15.1"
gem "image_processing", "~> 2.0", ">= 2.0.2"
gem "dartsass-rails", "~> 0.5.1"

# Client for the veil-core FastAPI service (see app/models/veil/base.rb).
gem "activeresource", github: "rails/activeresource", branch: "main"
gem "bcrypt", "~> 3.1"
gem "pagy", "~> 43.5"

gem "solid_cache"
gem "solid_cable"
gem "solid_queue"
gem "mission_control-jobs"

gem "kamal", "~> 2.11", require: false
gem "thruster", require: false

gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  # gem "annotate", "~> 3.2"
  gem "dotenv", require: false # load docker/secret-envs in bare (non-Docker) dev/test
  gem "brakeman", "~> 8.0", ">= 8.0.4", require: false
  gem "faker", "~> 3.8"
  gem "fasterer", "~> 0.11.0"
  gem "letter_opener_web", "~> 3.0"
  gem "pry", "~> 0.16.0"
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
  gem "simplecov", require: false

  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end

group :development do
  gem "web-console"
  gem "hotwire-spark", "~> 0.1.13"
  gem "ruby-lsp", "~> 0.26.9"
  gem "ruby-lsp-rails", "~> 0.4.8"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "capybara-screenshot", "~> 1.0", ">= 1.0.26"
  gem "capybara_watcher", "~> 0.1.2"
  gem "database_cleaner", "~> 2.0", ">= 2.0.2"
  gem "factory_bot_rails", "~> 6.4", ">= 6.4.3"
  gem "rack_session_access", "~> 0.2.0"
  gem "rails-controller-testing", "~> 1.0", ">= 1.0.5"
  gem "rspec-rails", "~> 8.0"
  gem "shoulda-matchers", "~> 7.0"
  gem "selenium-webdriver"
end
