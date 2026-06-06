module Veil
  # Base class for ActiveResource models backed by the veil-core FastAPI service.
  # Concrete resources (e.g. Veil::StegoImage) inherit from this once the core
  # exposes real endpoints. Mirrors the Luna::Base pattern from frp-uc.
  class Base < ActiveResource::Base
    cfg = Rails.application.config.veil

    self.site                   = "#{cfg[:address]}:#{cfg[:port]}"
    self.prefix                 = "/#{cfg[:api_version]}/"
    self.include_format_in_path = false
    self.ssl_options = { verify_mode: OpenSSL::SSL::VERIFY_NONE } if Rails.env.development?

    headers["X-Auth-Token"] = cfg[:token]

    # placeholder — no concrete resources yet; the core only serves /up and /.
  end
end
