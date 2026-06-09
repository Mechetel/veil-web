FactoryBot.define do
  factory :embedding do
    user
    input_image { association(:image, user: user) }
    params { { "model_key" => "dense-div2k", "message" => "secret" } }
  end
end
