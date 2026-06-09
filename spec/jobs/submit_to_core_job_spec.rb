require "rails_helper"

RSpec.describe SubmitToCoreJob, type: :job do
  it "delegates to the record's submit_to_core!" do
    embedding = create(:embedding)
    allow(Embedding).to receive(:find).and_return(embedding)
    expect(embedding).to receive(:submit_to_core!)

    described_class.perform_now(embedding)
  end
end
