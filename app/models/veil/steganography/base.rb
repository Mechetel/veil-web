module Veil
  module Steganography
    class Base < Veil::Base
      self.prefix = "#{superclass.prefix}steganography/"
    end
  end
end
