require "rails_helper"

RSpec.describe "Embeddings", type: :request do
  let(:user) { create(:user) }

  context "when signed in" do
    before { sign_in(user) }

    it "creates an embedding from a gallery image" do
      image = create(:image, user: user)

      expect {
        post embeddings_path, params: { model_key: "dense-div2k", message: "hi", image_id: image.id }
      }.to change(user.embeddings, :count).by(1)

      embedding = user.embeddings.last
      expect(embedding.model_key).to eq("dense-div2k")
      expect(embedding.input_image).to eq(image)
    end

    it "rejects a submission without an image" do
      post embeddings_path, params: { model_key: "dense-div2k", message: "hi" }
      expect(user.embeddings.count).to eq(0)
      expect(response).to redirect_to(root_path)
    end

    it "deletes a single embedding" do
      embedding = create(:embedding, user: user)
      expect { delete embedding_path(embedding) }.to change(user.embeddings, :count).by(-1)
    end

    it "deletes all embeddings" do
      create_list(:embedding, 2, user: user)
      expect { delete all_embeddings_path }.to change(user.embeddings, :count).by(-2)
    end

    it "cannot reach another user's embedding" do
      other = create(:embedding)
      get embedding_path(other)
      expect(response).to have_http_status(:not_found)
    end
  end

  it "requires authentication" do
    get embeddings_path
    expect(response).to redirect_to(new_session_path)
  end
end
