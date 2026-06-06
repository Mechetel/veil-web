CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Code: Zeitwerk", "bin/rails zeitwerk:check"
  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: Rails", "bin/rails test"
  step "Tests: Rspec", "bundle exec rspec spec"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  if success?
    step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  else
    failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  end
end
