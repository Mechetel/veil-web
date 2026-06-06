# require "simplecov"
# SimpleCov.start "rails"

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "shoulda/matchers"
require "capybara"
require "rack_session_access/capybara"

Rails.root.glob("spec/support/**/*.rb").each { |f| require f }
Rails.root.glob("spec/lib/**/*.rb").each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

RSpec.configure do |config|
  config.include CapybaraWatcher, type: :feature

  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!

  Shoulda::Matchers.configure do |shoulda_config|
    shoulda_config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  config.filter_rails_from_backtrace!
end
