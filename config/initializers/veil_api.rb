Rails.application.tap do |app|
  app.paths.add "config/veil", with: "config/veil.yml"
  if (config_path = Pathname.new(app.config.paths["config/veil"].first)).exist?
    app.config.veil = app.config_for(config_path).with_indifferent_access
  end
end
