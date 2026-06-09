require "base64"
require "stringio"

# Steganographic embedding (encode): hide a message inside a cover image.
# Named "Embedding" (not "Encoding") because ::Encoding is a Ruby core class.
class Embedding < ApplicationRecord
  include CoreProcessable

  # The stego result lives on the embedding (unlimited). It becomes a gallery
  # Image (output_image) only when the user explicitly saves it.
  has_one_attached :stego
  belongs_to :output_image, class_name: "Image", optional: true, dependent: :destroy

  validates :model_key, :message, presence: true

  def model_key = params["model_key"]
  def message   = params["message"]

  def core_resource_class = Veil::Steganography::Encode

  def core_payload
    { model_key: model_key, message: message }
  end

  def saved_to_gallery? = output_image_id.present?

  def apply_success!(payload)
    self.result = payload["result"] || {}
    b64 = payload["output_image_b64"]
    return if b64.blank?

    stego.attach(
      io: StringIO.new(Base64.decode64(b64)),
      filename: "stego-embedding-#{id}.png",
      content_type: "image/png"
    )
  end

  # Copy the stego result into the user's gallery (a fresh Image + blob).
  # Returns the Image, or nil when skipped (already saved, no result, or stego cap full).
  def save_to_gallery
    return output_image if saved_to_gallery?
    return nil unless succeeded? && stego.attached?

    image = user.images.new(kind: :stego, origin: :encoded, source_embedding: self,
                            metadata: { "model_key" => model_key })
    image.file.attach(io: StringIO.new(stego.download),
                      filename: "stego-#{id}.png", content_type: "image/png")
    return nil unless image.save # stego gallery full → skip

    update!(output_image: image)
    image
  end
end
