class DecodingsController < ApplicationController
  include TaskDeletion # destroy / bulk_destroy / destroy_all

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

    record = Current.user.decodings.new(input_image: input, params: { "model_key" => params[:model_key] })
    return flash_error(record.errors.full_messages.to_sentence) unless record.save

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Decoding queued"
        render turbo_stream: [
          turbo_stream.replace("decoding_form", partial: "decodings/form", locals: { decoding: Decoding.new }),
          flash_stream
        ]
      end
      format.html { redirect_to root_path, notice: "Decoding queued" }
    end
  end
end
