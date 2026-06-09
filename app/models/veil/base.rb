module Veil
  # Base class for ActiveResource models backed by the veil-core FastAPI service.
  # Domain resources live under Veil::Steganography::* and Veil::Steganalysis::*.
  # Mirrors the Luna::Base pattern from frp-uc.
  class Base < ActiveResource::Base
    cfg = Rails.application.config.veil || {}

    # Built at class-definition time, so it must not raise during eager load /
    # zeitwerk:check when the env (address/port) is absent. Fall back to a valid
    # placeholder URI; the real value comes from VEIL_CORE_ADDRESS at runtime.
    address = cfg[:address].presence || "http://localhost"
    port    = cfg[:port].presence

    self.site                   = [ address, port ].compact.join(":")
    self.prefix                 = "/#{cfg[:api_version].presence || 'v1'}/"
    self.include_format_in_path = false
    self.include_root_in_json   = false # core expects flat JSON bodies
    # Setting ssl_options at all forces ActiveResource to use TLS — so only do it
    # for an HTTPS core (e.g. self-signed in dev). Otherwise it would speak TLS to
    # the plain-HTTP dev core ("SSL_connect ... wrong version number").
    if Rails.env.development? && address.start_with?("https")
      self.ssl_options = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    end

    headers["X-Auth-Token"] = cfg[:token]
  end
end
