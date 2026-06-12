class DecodingsController < ApplicationController
  def index
    @decodings_pagy, @decodings = pagy(Current.user.decodings.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @decoding = Current.user.decodings.find(params[:id])
  end

  def new
    @decoding = Decoding.new
  end

  def create
    input = require_input_image(find_or_build_input_image(default_kind: :stego),
                                "Please choose or upload a stego image.")
    return if input.nil?

    Current.user.decodings.create!(input_image: input, params: { "model_key" => params[:model_key] })

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Decoding queued"
        render turbo_stream: [
          turbo_stream.replace("decoding_form", partial: "decodings/form", locals: { decoding: Decoding.new }),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html { redirect_to root_path, notice: "Decoding queued" }
    end
  end

  def destroy
    record = Current.user.decodings.find(params[:id])
    record.destroy
    return redirect_to(decodings_path, notice: "Decoding deleted") if params[:redirect].present?
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Decoding deleted"
        render turbo_stream: [ turbo_stream.remove(record), turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: "Decoding deleted" }
    end
  end

  def bulk_destroy
    records = Current.user.decodings.where(id: Array(params[:decoding_ids]).compact_blank).to_a
    records.each(&:destroy)
    flash.now[:notice] = "Deleted #{records.size} #{'decoding'.pluralize(records.size)}"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: records.map { |r| turbo_stream.remove(r) } +
                             [ turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: flash.now[:notice] }
    end
  end

  def destroy_all
    Current.user.decodings.destroy_all
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "All decodings deleted"
        render turbo_stream: [ turbo_stream.update("decodings", ""), turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: "All decodings deleted" }
    end
  end
end
