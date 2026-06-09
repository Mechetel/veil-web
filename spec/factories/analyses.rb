FactoryBot.define do
  factory :analysis do
    user
    input_image { association(:image, user: user) }
    params { { "analyzer_key" => "xunet-stego" } }
  end
end
