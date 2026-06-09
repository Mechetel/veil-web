# Gate the Mission Control jobs dashboard behind the app's auth (admins only)
# instead of the default HTTP basic auth (which 401s with no credentials set).
Rails.application.config.after_initialize do
  MissionControl::Jobs.http_basic_auth_enabled = false
  MissionControl::Jobs.base_controller_class   = "AdminController"
end
