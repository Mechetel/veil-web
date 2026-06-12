class AnalysesController < ApplicationController
  # "group:..." form values expand to every analyzer with that training set.
  ANALYZER_GROUPS = { "group:steganogan" => "stego", "group:alaska2" => "alaska2" }.freeze

  def index
    @images_pagy, @images = pagy(Image.analyzed_for(Current.user).with_attached_file,
                                 limit: 8, page_key: "analyses_page")
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @analysis = Current.user.analyses.find(params[:id])
  end

  def new
    @analysis = Analysis.new
  end

  # One submit can queue several analyses: a prepared group runs every analyzer
  # of that training set against the same image.
  def create
    input = require_input_image(find_or_build_input_image(default_kind: :stego),
                                "Please choose or upload an image.")
    return if input.nil?

    keys = analyzer_keys_from_params
    return redirect_to(root_path, alert: "Please choose a steganalyzer.") if keys.empty?

    created = keys.map do |key|
      Current.user.analyses.create!(input_image: input, params: { "analyzer_key" => key })
    end

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "#{created.size} #{'analysis'.pluralize(created.size)} queued"
        # The prepends/replace feed the per-image analyses page (no-ops elsewhere);
        # the grouped index cards update via the model broadcasts.
        render turbo_stream: [
          turbo_stream.replace("analysis_form", partial: "analyses/form", locals: { analysis: Analysis.new }),
          turbo_stream.update("flash", partial: "shared/flash")
        ] + created.map { |a|
          turbo_stream.prepend(dom_id_for(input, :all_analyses),
                               partial: "analyses/selectable_row", locals: { analysis: a })
        } + [ turbo_stream.replace(dom_id_for(input, :analyses_count),
                                   partial: "analyses/count_heading", locals: { image: input }) ]
      end
      format.html { redirect_back fallback_location: root_path, notice: "#{created.size} queued" }
    end
  end

  def destroy
    record = Current.user.analyses.find(params[:id])
    record.destroy
    return redirect_to(analyses_path, notice: "Analysis deleted") if params[:redirect].present?
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Analysis deleted"
        render turbo_stream: removal_streams([ record ]) +
                             [ turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: "Analysis deleted" }
    end
  end

  # Delete many analyses at once: by analysis_ids[] (rows on the per-image page)
  # or by image_ids[] (group cards on the analyze tab — ALL analyses of those images).
  def bulk_destroy
    scope = Current.user.analyses
    records = if params[:analysis_ids].present?
      scope.where(id: Array(params[:analysis_ids]).compact_blank)
    else
      scope.where(input_image_id: Array(params[:image_ids]).compact_blank)
    end.includes(:input_image).to_a

    records.each(&:destroy)
    flash.now[:notice] = "Deleted #{records.size} #{'analysis'.pluralize(records.size)}"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: removal_streams(records) +
                             [ turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_back fallback_location: root_path, notice: flash.now[:notice] }
    end
  end

  def destroy_all
    Current.user.analyses.destroy_all
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "All analyses deleted"
        render turbo_stream: [ turbo_stream.update("analyses", ""), turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: "All analyses deleted" }
    end
  end

  private

  def analyzer_keys_from_params
    selection = params[:analyzer_key].to_s
    if (training = ANALYZER_GROUPS[selection])
      CoreCatalog.analyzers.select { |a| a[:training].to_s == training }.map { |a| a[:key] }
    else
      [ selection ].reject(&:blank?)
    end
  end

  # Streams that clean up every place a deleted analysis appears: its bare row,
  # its selectable wrapper (per-image page), the image's group card (refreshed
  # or removed when empty) and the per-image count heading. Absent targets no-op.
  def removal_streams(records)
    streams = records.flat_map do |r|
      [ turbo_stream.remove(r), turbo_stream.remove(dom_id_for(r, :sel)) ]
    end
    records.map(&:input_image).compact.uniq.each do |image|
      streams << if image.analyses.exists?
        turbo_stream.replace(dom_id_for(image, :analyses),
                             partial: "analyses/image_analyses", locals: { image: image })
      else
        turbo_stream.remove(dom_id_for(image, :analyses))
      end
      streams << turbo_stream.replace(dom_id_for(image, :analyses_count),
                                      partial: "analyses/count_heading", locals: { image: image })
    end
    streams
  end

  def dom_id_for(record, prefix = nil)
    ActionView::RecordIdentifier.dom_id(record, prefix)
  end
end
