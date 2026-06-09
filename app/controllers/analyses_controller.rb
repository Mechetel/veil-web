class AnalysesController < ApplicationController
  def index
    @analyses_pagy, @analyses = pagy(Current.user.analyses.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
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

  def create
    input = find_or_build_input_image(default_kind: :stego)
    return redirect_to(root_path, alert: "Please choose or upload an image.") if input.nil?

    Current.user.analyses.create!(input_image: input, params: { "analyzer_key" => params[:analyzer_key] })

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Analysis queued"
        render turbo_stream: [
          turbo_stream.replace("analysis_form", partial: "analyses/form", locals: { analysis: Analysis.new }),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html { redirect_to root_path, notice: "Analysis queued" }
    end
  end

  def destroy
    record = Current.user.analyses.find(params[:id])
    record.destroy
    return redirect_to(analyses_path, notice: "Analysis deleted") if params[:redirect].present?
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Analysis deleted"
        render turbo_stream: [ turbo_stream.remove(record), turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: "Analysis deleted" }
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
end
