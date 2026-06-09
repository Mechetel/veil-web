require "base64"
require "stringio"

# 1x1 PNG
PNG_BYTES = Base64.decode64(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
)

FactoryBot.define do
  factory :image do
    user
    kind { :cover }
    origin { :uploaded }

    after(:build) do |image|
      image.file.attach(
        io: StringIO.new(PNG_BYTES),
        filename: "test.png",
        content_type: "image/png"
      )
    end
  end
end
