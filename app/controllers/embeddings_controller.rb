class EmbeddingsController < ApplicationController
  include TaskDeletion # destroy / bulk_destroy / destroy_all

  def index
    @embeddings_pagy, @embeddings = pagy(Current.user.embeddings.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
    respond_to do |format|
      format.html
      format.turbo_stream # load-more: append the page + refresh the button
    end
  end

  def show
    @embedding = Current.user.embeddings.find(params[:id])
  end

  def new
    @embedding = Embedding.new
  end

  def create
    input = require_input_image(find_or_build_input_image(default_kind: :cover),
                                "Please choose or upload a cover image.")
    return if input.nil?

    record = Current.user.embeddings.new(
      input_image: input,
      params: { "model_key" => params[:model_key], "message" => params[:message] }
    )
    return flash_error(record.errors.full_messages.to_sentence) unless record.save

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Encoding queued"
        render turbo_stream: [
          turbo_stream.replace("embedding_form", partial: "embeddings/form", locals: { embedding: Embedding.new }),
          flash_stream
        ]
      end
      format.html { redirect_to root_path, notice: "Encoding queued" }
    end
  end

  # Save the stego results of the selected embeddings into the gallery (stego cap).
  def save_to_gallery
    ids = Array(params[:embedding_ids]).compact_blank
    saved = []
    skipped = 0
    Current.user.embeddings.where(id: ids).find_each do |embedding|
      embedding.save_to_gallery ? (saved << embedding) : (skipped += 1)
    end
    if saved.any?
      flash.now[:notice] = "Saved #{saved.size} to gallery" +
        (skipped.positive? ? " · #{skipped} skipped (gallery full or already saved)" : "")
    else
      flash.now[:alert] = "Nothing saved (gallery full or already saved)"
    end

    respond_to do |format|
      format.turbo_stream do
        # Re-render each saved card so it immediately shows the "In gallery"
        # state (checkbox gone) without a reload; the save-counter controller
        # resets the bar on turbo:submit-end.
        render turbo_stream: [ flash_stream ] +
                             saved.map { |e| turbo_stream.replace(e, partial: "embeddings/embedding", locals: { embedding: e }) }
      end
      format.html { redirect_back fallback_location: root_path, notice: flash.now[:notice], alert: flash.now[:alert] }
    end
  end

  private

  # The UI calls embeddings "encodings" (::Encoding is a Ruby core class).
  def human_record_name = "Encoding"
end
