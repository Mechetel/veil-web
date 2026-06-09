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
end
