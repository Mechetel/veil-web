require "rails_helper"

RSpec.describe "Roles & gallery", type: :request do
  let(:user) { create(:user) }

  def png_upload(name = "pic.png")
    file = Tempfile.new([ name, ".png" ])
    file.binmode
    file.write(PNG_BYTES)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: name)
  end

  before { sign_in(user) }

  it "uploads several images at once" do
    expect {
      post images_path, params: { kind: "cover", images: [ png_upload("a.png"), png_upload("b.png") ] }
    }.to change(user.images, :count).by(2)
  end

  it "stores the model on a stego upload" do
    post images_path, params: { kind: "stego", model_key: "dense-div2k", images: [ png_upload ] }
    image = user.images.last
    expect(image.kind).to eq("stego")
    expect(image.model_key).to eq("dense-div2k")
  end

  it "load-more appends the next page as a turbo stream" do
    create_list(:embedding, 25, user: user)
    get embeddings_path(page: 2), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("turbo-stream").and include("append")
  end

  it "denies the jobs dashboard to non-admins" do
    get "/jobs"
    expect(response).to have_http_status(:redirect)
    expect(response.location).to eq("http://www.example.com/") # AdminController redirects to root
  end
end
