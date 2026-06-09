module Veil
  module Steganalysis
    # POST /v1/steganalysis/analyze  -> { id, status }
    class Analyze < Base
      self.element_name = "analyze"
      self.collection_name = "analyze"
    end
  end
end
