require "rails_helper"

# Render smoke tests — catch ERB/partial/helper errors. The core is not running,
# so CoreCatalog returns empty option lists (gracefully rescued).
RSpec.describe "Pages render", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  it "renders the studio dashboard" do
    create(:embedding, user: user)
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Encode").and include("Decode").and include("Analyze")
  end

  it "renders the gallery" do
    create(:image, user: user)
    get images_path
    expect(response).to have_http_status(:ok)
  end

  it "renders the resource index pages" do
    get embeddings_path
    get decodings_path
    get analyses_path
    expect(response).to have_http_status(:ok)
  end

  it "renders the profile" do
    get profile_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user.email_address)
  end

  it "renders the confirmation modal into the remote_modal frame" do
    embedding = create(:embedding, user: user)
    get confirmation_path(url: embedding_path(embedding), method: "delete",
                          title: "Delete this encoding?", message: "Are you sure?")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Delete this encoding?").and include("remote_modal")
  end
end
