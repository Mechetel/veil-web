require "capybara/rails"

Selenium::WebDriver::Chrome::Service.driver_path = "/usr/local/bin/chromedriver"
Capybara.server = :puma, { Silent: true }

###### WITH OPENED CHROME ######
# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, browser: :chrome)
# end

# Capybara.default_driver = :chrome
# Capybara.javascript_driver = :chrome
# Capybara.server_port = 3001

###### WITH CLOSED CHROME ######
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options:,
  )
end

Capybara.javascript_driver = :headless_chrome
