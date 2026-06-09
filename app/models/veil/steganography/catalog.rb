module Veil
  module Steganography
    # GET /v1/steganography/models  -> [ { key, family, label, dataset, data_depth, available } ]
    class Catalog < Base
      self.element_name = "model"
      self.collection_name = "models"

      def self.available
        all.select { |m| m.available }
      end
    end
  end
end
