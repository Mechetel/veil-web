# Shared constraints for image files users upload from their system
# (gallery images, task inputs, profile avatars):  PNG/JPG only, max 2 MB.
# Mirrored client-side in file_input/image_source Stimulus controllers —
# keep the two in sync. Usage:  validates :file, image_upload: true
class ImageUploadValidator < ActiveModel::EachValidator
  ALLOWED_TYPES = %w[image/png image/jpeg].freeze
  MAX_SIZE      = 2.megabytes

  def validate_each(record, attribute, attachment)
    return unless attachment.attached?

    unless attachment.content_type.in?(ALLOWED_TYPES)
      record.errors.add(attribute, "must be a PNG or JPG image")
      return
    end
    record.errors.add(attribute, "is too large (maximum is 2 MB)") if attachment.byte_size > MAX_SIZE
  end
end
