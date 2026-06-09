module Veil
  module Steganography
    # POST /v1/steganography/decode  -> { id, status }
    class Decode < Base
      self.element_name = "decode"
      self.collection_name = "decode"
    end
  end
end
