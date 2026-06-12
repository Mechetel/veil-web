class Image < ApplicationRecord
  # Constraints for files users upload from their system (server-side source of
  # truth; mirrored client-side in file_input/image_source Stimulus controllers).
  ALLOWED_UPLOAD_TYPES = %w[image/png image/jpeg].freeze
  MAX_UPLOAD_SIZE      = 2.megabytes

  belongs_to :user
  has_one_attached :file

  enum :kind,   { cover: 0, stego: 1 }
  # stock = copied from the shared public/default_images collection.
  enum :origin, { uploaded: 0, encoded: 1, stock: 2 }

  belongs_to :source_embedding, class_name: "Embedding", optional: true

  # Deleting an image deletes the operations that use it as input (and their
  # Active Storage blobs). The embeddings.output_image_id FK is nullified at the DB.
  has_many :embeddings, foreign_key: :input_image_id, dependent: :destroy
  has_many :decodings,  foreign_key: :input_image_id, dependent: :destroy
  has_many :analyses,   foreign_key: :input_image_id, dependent: :destroy

  validates :file, presence: true
  validate :within_kind_capacity
  # Only user-system uploads are constrained; core-generated stegos (encoded)
  # and the bundled defaults (stock) are trusted.
  validate :uploaded_file_constraints, if: :uploaded?

  scope :gallery, -> { order(created_at: :desc) }

  # Images that have at least one steganalysis, most recently analyzed first
  # (drives the grouped analyses listing).
  scope :analyzed_for, ->(user) {
    where(user: user)
      .where(id: user.analyses.select(:input_image_id))
      .order(Arel.sql("(SELECT MAX(a.created_at) FROM analyses a WHERE a.input_image_id = images.id) DESC"))
  }

  # The steg model this image was made with (set on encode, or chosen at upload).
  def model_key = metadata&.dig("model_key")

  private

  # Covers and stegos each have an independent per-user cap (admins exempt).
  # Only enforced when adding an image or changing its kind (convert cover→stego).
  def within_kind_capacity
    return unless user && !user.admin?
    return unless new_record? || kind_changed?

    limit = cover? ? User::COVER_LIMIT : User::STEGO_LIMIT
    used  = user.images.where(kind: self.class.kinds[kind]).where.not(id: id).count
    return if used < limit

    errors.add(:base, "#{kind.titleize} gallery is full (#{limit} max). Delete some to add more.")
  end

  def uploaded_file_constraints
    return unless file.attached?

    unless file.content_type.in?(ALLOWED_UPLOAD_TYPES)
      errors.add(:file, "must be a PNG or JPG image")
      return
    end
    errors.add(:file, "is too large (maximum is 2 MB)") if file.byte_size > MAX_UPLOAD_SIZE
  end
end
