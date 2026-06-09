module CatalogHelper
  def steg_model_options
    CoreCatalog.steg_models.map { |m| [ m[:label], m[:key] ] }
  end

  def analyzer_options
    CoreCatalog.analyzers.map { |a| [ a[:label], a[:key] ] }
  end

  def gallery_image_options(scope = Image.gallery.limit(100))
    scope.map { |img| [ "##{img.id} · #{img.kind} · #{img.created_at.strftime('%b %d %H:%M')}", img.id ] }
  end

  def status_badge(record)
    tag.span(record.status.titleize, class: "badge badge--#{record.status}")
  end
end
