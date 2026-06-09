# Base controller for admin-only areas. MissionControl::Jobs inherits from this
# (config.mission_control.jobs.base_controller_class), so /jobs requires an admin.
class AdminController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    return if Current.user&.admin?

    redirect_to main_app.root_path, alert: "Admins only." and return
  end
end
