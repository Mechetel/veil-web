module Veil
  module Steganalysis
    class Base < Veil::Base
      self.prefix = "#{superclass.prefix}steganalysis/"
    end
  end
end
