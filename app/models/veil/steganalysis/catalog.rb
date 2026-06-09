module Veil
  module Steganalysis
    # GET /v1/steganalysis/models  -> [ { key, arch, label, training, available } ]
    class Catalog < Base
      self.element_name = "model"
      self.collection_name = "models"

      def self.available
        all.select { |m| m.available }
      end
    end
  end
end
