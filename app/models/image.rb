class Image < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  enum :kind,   { cover: 0, stego: 1 }
  enum :origin, { uploaded: 0, encoded: 1 }

  belongs_to :source_embedding, class_name: "Embedding", optional: true

  # Deleting an image deletes the operations that use it as input (and their
  # Active Storage blobs). The embeddings.output_image_id FK is nullified at the DB.
  has_many :embeddings, foreign_key: :input_image_id, dependent: :destroy
  has_many :decodings,  foreign_key: :input_image_id, dependent: :destroy
  has_many :analyses,   foreign_key: :input_image_id, dependent: :destroy

  validates :file, presence: true
  validate :within_kind_capacity

  scope :gallery, -> { order(created_at: :desc) }

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
end
