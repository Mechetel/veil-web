module CoreCallbacks
  # Receives finished-job callbacks from veil-core. Token-authenticated (no CSRF):
  # the core sends X-Auth-Token == VEIL_CALLBACK_TOKEN and the signed client_ref
  # that identifies the originating record.
  class BaseController < ApplicationController
    allow_unauthenticated_access # token-authed from core, not a logged-in user
    skip_forgery_protection
    before_action :authenticate_core!

    def create
      record = GlobalID::Locator.locate_signed(params[:client_ref], for: "core_callback")
      return head(:not_found) if record.nil?

      record.apply_result!(callback_payload)
      head :ok
    end

    private

    def authenticate_core!
      provided = request.headers["X-Auth-Token"].to_s
      expected = Rails.application.config.veil[:callback_token].to_s
      return if expected.present? &&
                ActiveSupport::SecurityUtils.secure_compare(provided, expected)

      head :unauthorized
    end

    def callback_payload
      {
        "status"           => params[:status],
        "kind"             => params[:kind],
        "error"            => params[:error],
        "output_image_b64" => params[:output_image_b64],
        "result"           => params[:result].respond_to?(:to_unsafe_h) ? params[:result].to_unsafe_h : params[:result]
      }
    end
  end
end
