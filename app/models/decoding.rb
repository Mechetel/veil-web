class Decoding < ApplicationRecord
  include CoreProcessable

  validates :model_key, presence: true

  def model_key = params["model_key"]
  def message   = result["message"]

  def core_resource_class = Veil::Steganography::Decode

  def core_payload
    { model_key: model_key }
  end

  def apply_success!(payload)
    self.result = payload["result"] || {}
  end
end
