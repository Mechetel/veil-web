require "rails_helper"

# Form errors must NOT navigate away: Turbo submissions get a flash-toast
# turbo-stream (status 200, no redirect), so the user stays on their tab.
# Non-Turbo requests fall back to redirect_back.
RSpec.describe "Form errors without reload", type: :request do
  TURBO = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  let(:user) { create(:user) }
  before { sign_in(user) }

  it "missing image on encode → toast, no redirect" do
    post embeddings_path, params: { model_key: "dense-div2k", message: "hi" }, headers: TURBO
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include(%(action="prepend")).and include("choose or upload a cover image")
    expect(user.embeddings.count).to eq(0)
  end

  it "missing message on encode → toast with the validation error" do
    image = create(:image, user: user)
    post embeddings_path, params: { model_key: "dense-div2k", image_id: image.id }, headers: TURBO
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(CGI.escapeHTML("Message can't be blank"))
    expect(user.embeddings.count).to eq(0)
  end

  it "missing analyzer on analyze → toast, no redirect" do
    image = create(:image, user: user)
    post analyses_path, params: { image_id: image.id }, headers: TURBO
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("choose a steganalyzer")
    expect(user.analyses.count).to eq(0)
  end

  it "missing model on decode → toast with the validation error" do
    image = create(:image, user: user, kind: :stego, origin: :encoded)
    post decodings_path, params: { image_id: image.id }, headers: TURBO
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(CGI.escapeHTML("Model key can't be blank"))
    expect(user.decodings.count).to eq(0)
  end

  it "empty gallery upload → toast, no redirect" do
    post images_path, params: { kind: "cover" }, headers: TURBO
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Choose at least one image")
  end

  it "non-Turbo requests still redirect back with the alert (fallback)" do
    post embeddings_path, params: { model_key: "dense-div2k", message: "hi" }
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to include("choose or upload")
  end
end
