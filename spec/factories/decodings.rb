FactoryBot.define do
  factory :decoding do
    user
    input_image { association(:image, user: user) }
    params { { "model_key" => "dense-div2k" } }
  end
end
