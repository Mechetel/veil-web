# Cached, failure-tolerant access to veil-core's model catalogs. If the core is
# unreachable the UI still renders (with empty selects) instead of erroring.
module CoreCatalog
  module_function

  def steg_models
    fetch("veil/steg_models") do
      Veil::Steganography::Catalog.available.map do |m|
        { key: m.key, label: m.label, family: m.family, dataset: m.dataset, data_depth: m.data_depth }
      end
    end
  end

  def analyzers
    fetch("veil/analyzers") do
      Veil::Steganalysis::Catalog.available.map do |a|
        { key: a.key, label: a.label, arch: a.arch, training: a.training }
      end
    end
  end

  def fetch(key)
    Rails.cache.fetch(key, expires_in: 5.minutes) { yield }
  rescue StandardError => e
    Rails.logger.warn("CoreCatalog #{key} failed: #{e.class}: #{e.message}")
    []
  end
end
