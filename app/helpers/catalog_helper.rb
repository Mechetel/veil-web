module CatalogHelper
  def steg_model_options
    CoreCatalog.steg_models.map { |m| [ m[:label], m[:key] ] }
  end

  def analyzer_options
    CoreCatalog.analyzers.map { |a| [ a[:label], a[:key] ] }
  end

  # Grouped select: prepared analyzer groups (by training set) first, then the
  # single analyzers. Group values are "group:steganogan" / "group:alaska2" and
  # are expanded to keys in AnalysesController.
  def analyzer_select_options(selected = nil)
    analyzers = CoreCatalog.analyzers
    groups = [ [ "SteganoGAN-trained", "stego", "group:steganogan" ],
               [ "Alaska2-trained",    "alaska2", "group:alaska2" ] ].filter_map do |label, training, value|
      n = analyzers.count { |a| a[:training].to_s == training }
      [ "#{label} — all #{n}", value ] if n.positive?
    end
    grouped_options_for_select(
      [ [ "Analyzer groups", groups ], [ "Single analyzers", analyzer_options ] ], selected
    )
  end

  def gallery_image_options(scope = Image.gallery.limit(100))
    scope.map { |img| [ "##{img.id} · #{img.kind} · #{img.created_at.strftime('%b %d %H:%M')}", img.id ] }
  end

  def status_badge(record)
    tag.span(record.status.titleize, class: "badge badge--#{record.status}")
  end
end
