require "rails_helper"
require "tempfile"

RSpec.describe "Bulk actions & profile avatar", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  describe "decodings bulk delete" do
    it "deletes only the selected decodings" do
      keep   = create(:decoding, user: user)
      victims = create_list(:decoding, 2, user: user)
      expect {
        post bulk_destroy_decodings_path, params: { decoding_ids: victims.map(&:id) }
      }.to change(user.decodings, :count).by(-2)
      expect(user.decodings).to contain_exactly(keep)
    end

    it "cannot delete another user's decodings" do
      other = create(:decoding)
      post bulk_destroy_decodings_path, params: { decoding_ids: [ other.id ] }
      expect(Decoding.exists?(other.id)).to be(true)
    end
  end

  describe "analyses bulk delete" do
    it "deletes ALL analyses of the selected images (image_ids mode)" do
      img_a = create(:image, user: user)
      img_b = create(:image, user: user)
      create_list(:analysis, 3, user: user, input_image: img_a)
      kept = create(:analysis, user: user, input_image: img_b)

      expect {
        post bulk_destroy_analyses_path, params: { image_ids: [ img_a.id ] }
      }.to change(user.analyses, :count).by(-3)
      expect(user.analyses).to contain_exactly(kept)
    end

    it "deletes the selected analyses (analysis_ids mode) and refreshes the count" do
      img = create(:image, user: user)
      victims = create_list(:analysis, 2, user: user, input_image: img)
      create(:analysis, user: user, input_image: img)

      post bulk_destroy_analyses_path, params: { analysis_ids: victims.map(&:id) },
                                       headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(user.analyses.count).to eq(1)
      expect(response.body).to include("analyses_count_image_#{img.id}").and include("1 analysis")
    end
  end

  describe "per-image analyses page live updates" do
    let(:catalog) { [ { key: "xunet-stego", label: "XuNet", arch: "xunet", training: "stego" } ] }
    before { allow(CoreCatalog).to receive(:analyzers).and_return(catalog) }

    it "prepends the new (selectable) rows in the create response" do
      img = create(:image, user: user)
      post analyses_path, params: { analyzer_key: "xunet-stego", image_id: img.id },
                          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      analysis = user.analyses.last
      expect(response.body).to include(%(action="prepend")).and include("all_analyses_image_#{img.id}")
      expect(response.body).to include("sel_analysis_#{analysis.id}") # selectable wrapper
      expect(response.body).to include("analyses_count_image_#{img.id}")
    end

    it "bumps the image's group card in the create response (index/tab live update)" do
      img = create(:image, user: user)
      post analyses_path, params: { analyzer_key: "xunet-stego", image_id: img.id },
                          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.body).to include(%(target="analyses")).and include("analyses_image_#{img.id}")
    end

    it "shows the run-analysis form on the analyses index page" do
      get analyses_path
      expect(response.body).to include("analysis_form").and include("Run steganalysis")
    end
  end

  describe "profile avatar upload" do
    def png_avatar
      file = Tempfile.new([ "a", ".png" ])
      file.binmode
      file.write(PNG_BYTES)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, "image/png", original_filename: "me.png")
    end

    it "attaches a PNG avatar" do
      patch profile_path, params: { user: { avatar: png_avatar } }
      expect(response).to redirect_to(profile_path)
      expect(user.reload.avatar).to be_attached
    end

    it "rejects a non-image avatar" do
      file = Tempfile.new([ "a", ".txt" ])
      file.write("hello")
      file.rewind
      bad = Rack::Test::UploadedFile.new(file.path, "text/plain", original_filename: "a.txt")
      patch profile_path, params: { user: { avatar: bad } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.avatar).not_to be_attached
    end
  end
end
