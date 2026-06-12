require "rails_helper"
require "tempfile"

# Server-side constraints for files uploaded from the user's system:
# PNG/JPG only, max 2 MB. Core-generated stegos and bundled defaults are exempt.
RSpec.describe "Upload validation", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  def upload(bytes, name:, type:)
    file = Tempfile.new([ "u", File.extname(name) ])
    file.binmode
    file.write(bytes)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, type, original_filename: name)
  end

  it "accepts a small PNG" do
    expect {
      post images_path, params: { kind: "cover", images: [ upload(PNG_BYTES, name: "ok.png", type: "image/png") ] }
    }.to change(user.images, :count).by(1)
  end

  it "rejects a non-PNG/JPG file" do
    expect {
      post images_path, params: { kind: "cover", images: [ upload("GIF89a....", name: "x.gif", type: "image/gif") ] }
    }.not_to change(user.images, :count)
    follow_redirect!
    expect(response.body).to include("PNG or JPG")
  end

  it "rejects a file over 2 MB" do
    big = PNG_BYTES + ("\x00" * (2.megabytes + 1024)).b
    expect {
      post images_path, params: { kind: "cover", images: [ upload(big, name: "big.png", type: "image/png") ] }
    }.not_to change(user.images, :count)
    follow_redirect!
    expect(response.body).to include("too large")
  end

  it "rejects an invalid upload as the encode input with an alert" do
    post embeddings_path, params: { model_key: "dense-div2k", message: "hi",
                                    image: upload("plain text", name: "x.txt", type: "text/plain") }
    expect(user.embeddings.count).to eq(0)
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to include("PNG or JPG")
  end

  it "does not constrain core-generated stego images (origin encoded)" do
    img = build(:image, user: user, kind: :stego, origin: :encoded)
    img.file.attach(io: StringIO.new("not-a-real-png".b), filename: "s.bin", content_type: "application/octet-stream")
    expect(img).to be_valid
  end
end
