class User < ApplicationRecord
  COVER_LIMIT = 40
  STEGO_LIMIT = 40

  has_secure_password
  has_many :sessions, dependent: :destroy

  # Optional uploaded profile image; the generated-initials avatar
  # (AvatarsController) stays as the fallback.
  has_one_attached :avatar

  has_many :images,     dependent: :destroy
  has_many :embeddings, dependent: :destroy
  has_many :decodings,  dependent: :destroy
  has_many :analyses,   dependent: :destroy

  enum :role, { simple: 0, admin: 1 }, default: :simple

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip.presence }

  validates :email_address, presence: true
  validates :username, length: { in: 2..30 }, format: { with: /\A[\w.\- ]+\z/ },
                       uniqueness: { case_sensitive: false }, allow_nil: true
  validates :avatar, image_upload: true # PNG/JPG, ≤2 MB (ImageUploadValidator)

  # Token for the forgot-password flow (invalidated when the password changes).
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  def cover_count = images.cover.count
  def stego_count = images.stego.count
  def cover_full? = !admin? && cover_count >= COVER_LIMIT
  def stego_full? = !admin? && stego_count >= STEGO_LIMIT

  def display_name
    username.presence || email_address.split("@").first
  end

  # Safe display source: an attachment assigned during a FAILED update is still
  # in memory (attached? is true) but has no signed URL yet — show only a
  # persisted avatar, otherwise the generated fallback.
  def persisted_avatar
    avatar if avatar.attached? && avatar.attachment.persisted?
  end
end
