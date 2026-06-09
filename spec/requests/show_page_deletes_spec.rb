require "rails_helper"

# Deleting from a *show* (detail) page sends ?redirect=1 with the DELETE. The
# destroy action must then redirect to that resource's index page with a flash —
# never leave the user stranded on the just-deleted record. Deleting from a list
# keeps the in-place Turbo Stream behaviour (no redirect).
RSpec.describe "Deleting from show pages", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  it "redirects an encoding delete to the encodings index" do
    embedding = create(:embedding, user: user)
    expect { delete embedding_path(embedding, redirect: 1) }.to change(user.embeddings, :count).by(-1)
    expect(response).to redirect_to(embeddings_path)
    expect(flash[:notice]).to eq("Encoding deleted")
  end

  it "redirects a decoding delete to the decodings index" do
    decoding = create(:decoding, user: user)
    expect { delete decoding_path(decoding, redirect: 1) }.to change(user.decodings, :count).by(-1)
    expect(response).to redirect_to(decodings_path)
    expect(flash[:notice]).to eq("Decoding deleted")
  end

  it "redirects an analysis delete to the analyses index" do
    analysis = create(:analysis, user: user)
    expect { delete analysis_path(analysis, redirect: 1) }.to change(user.analyses, :count).by(-1)
    expect(response).to redirect_to(analyses_path)
    expect(flash[:notice]).to eq("Analysis deleted")
  end

  it "redirects an image delete to the gallery (images index)" do
    image = create(:image, user: user)
    expect { delete image_path(image, redirect: 1) }.to change(user.images, :count).by(-1)
    expect(response).to redirect_to(images_path)
    expect(flash[:notice]).to eq("Image deleted")
  end

  it "does NOT redirect to the index when deleting from a list (Turbo Stream)" do
    embedding = create(:embedding, user: user)
    delete embedding_path(embedding), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include(%(action="remove"))
    expect(response).not_to redirect_to(embeddings_path)
  end
end
