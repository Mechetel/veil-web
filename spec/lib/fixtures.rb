module Lib
  module Fixtures
    def local_fixture_path(path)
      Rails.root.join("spec/fixtures").to_s + path
    end
  end
end
