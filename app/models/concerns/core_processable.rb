require "base64"

# Shared async machinery for the three task models (Encoding, Decoding, Analysis).
#
# Lifecycle: pending → queued (core accepted) → processing → succeeded | failed.
# On create we enqueue SubmitToCoreJob and broadcast the new card; the core calls
# back when finished and `apply_result!` flips the status + stores the result,
# broadcasting the replacement card.
#
# Each including model must implement:
#   #core_resource_class  -> ActiveResource class (Veil::...)
#   #core_payload         -> Hash of domain params (image_b64 + client_ref are added here)
#   #apply_success!(payload) -> store the domain-specific result
module CoreProcessable
  extend ActiveSupport::Concern

  STATUSES = { pending: 0, queued: 1, processing: 2, succeeded: 3, failed: 4 }.freeze

  included do
    enum :status, STATUSES, default: :pending

    belongs_to :user, default: -> { Current.user }
    belongs_to :input_image, class_name: "Image"

    validates :status, presence: true

    scope :recent, -> { order(created_at: :desc) }

    after_create_commit :enqueue_submit
    after_create_commit :broadcast_created
    after_update_commit :broadcast_updated
  end

  # ── async orchestration ────────────────────────────────────────────────────

  # Called by SubmitToCoreJob. Sends the job to veil-core over ActiveResource.
  def submit_to_core!
    resource = core_resource_class.new(
      core_payload.merge(image_b64: input_image_base64, client_ref: client_ref_token)
    )
    resource.save!
    update!(status: :queued, core_job_id: resource.id.to_s, enqueued_at: Time.current)
  rescue StandardError => e
    fail!("#{e.class}: #{e.message}")
  end

  # Signed, tamper-proof reference the core echoes back in its callback.
  def client_ref_token
    to_sgid(for: "core_callback").to_param
  end

  # Called by the core callback controller with the finished payload.
  def apply_result!(payload)
    if payload["status"] == "succeeded"
      apply_success!(payload)
      self.status = :succeeded
    else
      self.status = :failed
      self.error_message = payload["error"].presence || "core reported failure"
    end
    self.finished_at = Time.current
    save!
  end

  def in_flight?
    pending? || queued? || processing?
  end

  private

  def fail!(message)
    update!(status: :failed, error_message: message, finished_at: Time.current)
  end

  def enqueue_submit
    SubmitToCoreJob.perform_later(self)
  end

  def input_image_base64
    Base64.strict_encode64(input_image.file.download)
  end

  # ── Turbo Stream broadcasts ────────────────────────────────────────────────

  # Per-user stream channel (privacy): only the owner's page is subscribed.
  def stream_name
    [ user, self.class.model_name.plural ]
  end

  # DOM id of the list container on the page.
  def dom_target
    self.class.model_name.plural # "embeddings" / "decodings" / "analyses"
  end

  def partial_name
    "#{self.class.model_name.plural}/#{self.class.model_name.element}"
  end

  def partial_locals
    { self.class.model_name.element.to_sym => self }
  end

  def broadcast_created
    broadcast_prepend_to stream_name, target: dom_target,
                                      partial: partial_name, locals: partial_locals
  end

  def broadcast_updated
    broadcast_replace_to stream_name, partial: partial_name, locals: partial_locals
    broadcast_replace_to self, partial: partial_name, locals: partial_locals
  end
end
