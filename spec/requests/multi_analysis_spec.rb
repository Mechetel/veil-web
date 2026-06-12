require "rails_helper"

RSpec.describe "Multi-analysis", type: :request do
  let(:user) { create(:user) }
  before { sign_in(user) }

  let(:catalog) do
    [
      { key: "xunet-stego",  label: "XuNet (stego)",   arch: "xunet", training: "stego" },
      { key: "srnet-stego",  label: "SRNet (stego)",   arch: "srnet", training: "stego" },
      { key: "srnet-alaska", label: "SRNet (alaska2)", arch: "srnet", training: "alaska2" }
    ]
  end
  before { allow(CoreCatalog).to receive(:analyzers).and_return(catalog) }

  it "queues one analysis for a single analyzer" do
    image = create(:image, user: user)
    expect {
      post analyses_path, params: { analyzer_key: "xunet-stego", image_id: image.id }
    }.to change(user.analyses, :count).by(1)
  end

  it "queues an analysis per analyzer of the selected group" do
    image = create(:image, user: user)
    expect {
      post analyses_path, params: { analyzer_key: "group:steganogan", image_id: image.id }
    }.to change(user.analyses, :count).by(2)
    expect(user.analyses.map(&:analyzer_key)).to match_array(%w[xunet-stego srnet-stego])
    expect(user.analyses.map(&:input_image_id).uniq).to eq([ image.id ])
  end

  it "expands the alaska2 group" do
    image = create(:image, user: user)
    post analyses_path, params: { analyzer_key: "group:alaska2", image_id: image.id }
    expect(user.analyses.map(&:analyzer_key)).to eq(%w[srnet-alaska])
  end

  it "groups the analyses index by image" do
    image = create(:image, user: user)
    create_list(:analysis, 2, user: user, input_image: image)
    get analyses_path
    expect(response.body).to include("analyses_image_#{image.id}")
  end

  it "shows ALL analyses of one image on its analyses page" do
    image = create(:image, user: user)
    analyses = create_list(:analysis, 7, user: user, input_image: image)
    get analyses_image_path(image)
    expect(response).to have_http_status(:ok)
    analyses.each { |a| expect(response.body).to include("analysis_#{a.id}") }
    expect(response.body).to include("7 analyses")
  end

  it "links to the analyses page from the image show page" do
    image = create(:image, user: user)
    get image_path(image)
    expect(response.body).to include(analyses_image_path(image))
  end

  it "uses a default image as the analysis input (copied into the gallery)" do
    name = DefaultImages.all.first
    skip "no default images bundled" if name.nil?
    expect {
      post analyses_path, params: { analyzer_key: "xunet-stego", default_image: name }
    }.to change(user.images.stock, :count).by(1).and change(user.analyses, :count).by(1)
  end
end
