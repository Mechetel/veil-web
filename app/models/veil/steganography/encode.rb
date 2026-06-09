module Veil
  module Steganography
    # POST /v1/steganography/encode  -> { id, status }
    class Encode < Base
      self.element_name = "encode"
      self.collection_name = "encode"
    end
  end
end
