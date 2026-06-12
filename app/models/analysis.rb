class Analysis < ApplicationRecord
  include CoreProcessable

  validates :analyzer_key, presence: true

  def analyzer_key = params["analyzer_key"]
  def prob_stego   = result["prob_stego"]
  def label        = result["label"]

  def core_resource_class = Veil::Steganalysis::Analyze

  def core_payload
    { analyzer_key: analyzer_key }
  end

  def apply_success!(payload)
    self.result = payload["result"] || {}
  end

  private

  # Analyses are displayed grouped by photo (last 5 per card on the index, all
  # rows on the per-image page), so the concern's flat-card broadcasts are
  # replaced: a new analysis re-renders its image's group card at the top of
  # #analyses and prepends a row on the per-image page; a status change just
  # replaces the row in place (same dom_id on both pages).
  def broadcast_created
    image = input_image
    broadcast_remove_to stream_name, target: ActionView::RecordIdentifier.dom_id(image, :analyses)
    broadcast_prepend_to stream_name, target: "analyses",
                                      partial: "analyses/image_analyses", locals: { image: image }
    broadcast_prepend_to stream_name, target: ActionView::RecordIdentifier.dom_id(image, :all_analyses),
                                      partial: "analyses/analysis_row", locals: { analysis: self }
  end

  def broadcast_updated
    broadcast_replace_to stream_name, target: ActionView::RecordIdentifier.dom_id(self),
                                      partial: "analyses/analysis_row", locals: { analysis: self }
  end
end
