require "rails_helper"

RSpec.describe Image, type: :model do
  it "has kind and origin enums" do
    expect(Image.kinds.keys).to contain_exactly("cover", "stego")
    expect(Image.origins.keys).to contain_exactly("uploaded", "encoded")
  end

  it "requires an attached file" do
    image = Image.new(kind: :cover, origin: :uploaded, user: create(:user))
    expect(image).not_to be_valid
    expect(image.errors[:file]).to be_present
  end

  it "is valid with an attached file" do
    expect(build(:image)).to be_valid
  end

  it "caps covers per user" do
    user = create(:user)
    create_list(:image, User::COVER_LIMIT, user: user)
    extra = build(:image, user: user, kind: :cover)
    expect(extra.save).to be(false)
    expect(extra.errors[:base].join).to match(/Cover gallery is full/)
  end

  it "caps stegos independently of covers" do
    user = create(:user)
    create_list(:image, User::STEGO_LIMIT, user: user, kind: :stego, origin: :encoded)
    expect(build(:image, user: user, kind: :cover).save).to be(true)
    expect(build(:image, user: user, kind: :stego, origin: :encoded).save).to be(false)
  end

  it "destroying an image destroys the operations that use it" do
    user  = create(:user)
    image = create(:image, user: user)
    create(:embedding, user: user, input_image: image)
    create(:decoding,  user: user, input_image: image)
    create(:analysis,  user: user, input_image: image)

    expect { image.destroy }
      .to change(Embedding, :count).by(-1)
      .and change(Decoding, :count).by(-1)
      .and change(Analysis, :count).by(-1)
  end
end
