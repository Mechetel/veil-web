require "rails_helper"
require "base64"

RSpec.describe Embedding, type: :model do
  it "defaults to pending and is in_flight" do
    embedding = build(:embedding)
    expect(embedding.status).to eq("pending")
    expect(embedding.in_flight?).to be(true)
  end

  it "exposes model_key and message from params" do
    embedding = build(:embedding, params: { "model_key" => "edge_aspp-div2k-d1", "message" => "hi" })
    expect(embedding.model_key).to eq("edge_aspp-div2k-d1")
    expect(embedding.message).to eq("hi")
  end

  it "builds the core payload" do
    embedding = build(:embedding)
    expect(embedding.core_payload).to eq(model_key: "dense-div2k", message: "secret")
    expect(embedding.core_resource_class).to eq(Veil::Steganography::Encode)
  end

  describe "#submit_to_core!" do
    it "queues the record and stores the core job id on success" do
      embedding = create(:embedding)
      resource = instance_double(Veil::Steganography::Encode, save!: true, id: "job-123")
      allow(Veil::Steganography::Encode).to receive(:new).and_return(resource)

      embedding.submit_to_core!

      expect(embedding.reload.status).to eq("queued")
      expect(embedding.core_job_id).to eq("job-123")
    end

    it "marks failed when the core call raises" do
      embedding = create(:embedding)
      allow(Veil::Steganography::Encode).to receive(:new).and_raise(StandardError.new("boom"))

      embedding.submit_to_core!

      expect(embedding.reload.status).to eq("failed")
      expect(embedding.error_message).to include("boom")
    end
  end

  describe "#apply_result!" do
    it "attaches the stego result (not a gallery image) on success" do
      embedding = create(:embedding)
      b64 = Base64.strict_encode64(PNG_BYTES)

      expect {
        embedding.apply_result!("status" => "succeeded", "result" => {}, "output_image_b64" => b64)
      }.not_to change(Image, :count)

      expect(embedding.reload.status).to eq("succeeded")
      expect(embedding.stego).to be_attached
      expect(embedding.saved_to_gallery?).to be(false)
    end

    it "save_to_gallery copies the stego into a gallery image" do
      embedding = create(:embedding)
      embedding.apply_result!("status" => "succeeded", "result" => {}, "output_image_b64" => Base64.strict_encode64(PNG_BYTES))

      expect { embedding.save_to_gallery }.to change(Image, :count).by(1)
      expect(embedding.reload.saved_to_gallery?).to be(true)
      expect(embedding.output_image.kind).to eq("stego")
    end

    it "marks failed and records the error" do
      embedding = create(:embedding)
      embedding.apply_result!("status" => "failed", "error" => "no capacity")
      expect(embedding.reload.status).to eq("failed")
      expect(embedding.error_message).to eq("no capacity")
    end
  end
end
