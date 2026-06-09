require "rails_helper"
require "base64"
require "tempfile"

RSpec.describe "Gallery & profile", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  def png_upload(name = "p.png")
    file = Tempfile.new([ name, ".png" ])
    file.binmode
    file.write(PNG_BYTES)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: name)
  end

  def succeeded_embedding
    e = create(:embedding, user: user)
    e.apply_result!("status" => "succeeded", "result" => {}, "output_image_b64" => Base64.strict_encode64(PNG_BYTES))
    e
  end

  it "renders the gallery with Covers and Stegos tabs" do
    create(:image, user: user, kind: :cover)
    create(:image, user: user, kind: :stego, origin: :encoded)
    get images_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Covers").and include("Stegos")
  end

  it "uploads multiple images at once" do
    expect {
      post images_path, params: { kind: "cover", images: [ png_upload("a.png"), png_upload("b.png") ] }
    }.to change(user.images.cover, :count).by(2)
  end

  it "stores the model on a stego upload" do
    post images_path, params: { kind: "stego", model_key: "dense-div2k", images: [ png_upload ] }
    expect(user.images.stego.last.model_key).to eq("dense-div2k")
  end

  it "saves selected embeddings' stego to the gallery" do
    embedding = succeeded_embedding
    expect {
      post save_to_gallery_embeddings_path, params: { embedding_ids: [ embedding.id ] }
    }.to change(user.images.stego, :count).by(1)
    expect(embedding.reload.saved_to_gallery?).to be(true)
  end

  it "bulk-deletes selected images" do
    imgs = create_list(:image, 2, user: user)
    expect {
      post bulk_destroy_images_path, params: { image_ids: imgs.map(&:id) }
    }.to change(user.images, :count).by(-2)
  end

  it "bulk-updates the model on stego images" do
    stego = create(:image, user: user, kind: :stego, origin: :encoded)
    post bulk_update_model_images_path, params: { image_ids: [ stego.id ], model_key: "edge_aspp-div2k-d1" }
    expect(stego.reload.model_key).to eq("edge_aspp-div2k-d1")
  end

  it "converts a cover to stego" do
    cover = create(:image, user: user, kind: :cover)
    patch image_path(cover), params: { kind: "stego", model_key: "dense-div2k" }
    expect(cover.reload.kind).to eq("stego")
    expect(cover.model_key).to eq("dense-div2k")
  end

  it "renders the profile and a PNG avatar" do
    get profile_path
    expect(response).to have_http_status(:ok)
    get avatar_path
    expect(response.media_type).to eq("image/png")
  end

  it "changes the password with the correct current password" do
    patch password_change_path, params: { current_password: "password123", password: "newpass123", password_confirmation: "newpass123" }
    expect(user.reload.authenticate("newpass123")).to be_truthy
  end

  it "rejects a password change with the wrong current password" do
    patch password_change_path, params: { current_password: "nope", password: "x1234567", password_confirmation: "x1234567" }
    expect(user.reload.authenticate("password123")).to be_truthy
  end

  it "accepts a forgot-password request" do
    post passwords_path, params: { email_address: user.email_address }
    expect(response).to redirect_to(new_session_path)
  end
end
