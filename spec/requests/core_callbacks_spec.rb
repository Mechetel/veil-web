require "rails_helper"
require "base64"

RSpec.describe "Core callbacks", type: :request do
  let(:token) { Rails.application.config.veil[:callback_token] }

  it "applies a steganography (encode) result with a valid token" do
    embedding = create(:embedding)

    post "/callbacks/steganography",
         params: {
           client_ref: embedding.client_ref_token,
           status: "succeeded", kind: "encode",
           result: {}, output_image_b64: Base64.strict_encode64(PNG_BYTES)
         },
         headers: { "X-Auth-Token" => token }

    expect(response).to have_http_status(:ok)
    expect(embedding.reload.status).to eq("succeeded")
    expect(embedding.stego).to be_attached
  end

  it "rejects an invalid token" do
    embedding = create(:embedding)

    post "/callbacks/steganography",
         params: { client_ref: embedding.client_ref_token, status: "succeeded" },
         headers: { "X-Auth-Token" => "wrong" }

    expect(response).to have_http_status(:unauthorized)
    expect(embedding.reload.status).to eq("pending")
  end

  it "applies a steganalysis result" do
    analysis = create(:analysis)

    post "/callbacks/steganalysis",
         params: {
           client_ref: analysis.client_ref_token,
           status: "succeeded", kind: "analyze",
           result: { prob_stego: 0.9, label: "stego" }
         },
         headers: { "X-Auth-Token" => token }

    expect(response).to have_http_status(:ok)
    expect(analysis.reload.label).to eq("stego")
  end
end
