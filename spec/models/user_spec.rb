require "rails_helper"

RSpec.describe User, type: :model do
  it "defaults to the simple role" do
    expect(create(:user).role).to eq("simple")
  end

  it "can be an admin" do
    expect(create(:user, role: :admin)).to be_admin
  end

  it "uses username for display_name, falling back to email" do
    expect(create(:user, username: "neo").display_name).to eq("neo")
    expect(create(:user, username: nil, email_address: "trinity@example.com").display_name).to eq("trinity")
  end

  it "admins are exempt from the gallery caps" do
    admin = create(:user, role: :admin)
    create_list(:image, User::COVER_LIMIT + 2, user: admin)
    expect(admin.cover_full?).to be(false)
    expect(build(:image, user: admin).save).to be(true)
  end
end
