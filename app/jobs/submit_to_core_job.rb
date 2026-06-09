# Sends a task record (Encoding/Decoding/Analysis) to veil-core over ActiveResource.
# DRY across all three domains via the CoreProcessable concern.
class SubmitToCoreJob < ApplicationJob
  queue_as :default

  def perform(record)
    record.submit_to_core!
  end
end
