class EmbeddingsController < ApplicationController
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
    input = find_or_build_input_image(default_kind: :cover)
    return redirect_to(root_path, alert: "Please choose or upload a cover image.") if input.nil?

    Current.user.embeddings.create!(
      input_image: input,
      params: { "model_key" => params[:model_key], "message" => params[:message] }
    )

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Encoding queued"
        render turbo_stream: [
          turbo_stream.replace("embedding_form", partial: "embeddings/form", locals: { embedding: Embedding.new }),
          turbo_stream.update("flash", partial: "shared/flash")
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
        # Re-render each saved card so it immediately shows the "In gallery" state
        # (checkbox gone) without a reload; the save-counter controller resets the
        # bar on turbo:submit-end. update (not replace) keeps the .flashes wrapper.
        render turbo_stream: [
          turbo_stream.update("flash", partial: "shared/flash")
        ] + saved.map { |e| turbo_stream.replace(e, partial: "embeddings/embedding", locals: { embedding: e }) }
      end
      format.html { redirect_back fallback_location: root_path, notice: flash.now[:notice], alert: flash.now[:alert] }
    end
  end

  def bulk_destroy
    records = Current.user.embeddings.where(id: Array(params[:embedding_ids]).compact_blank).to_a
    records.each(&:destroy)
    flash.now[:notice] = "Deleted #{records.size} #{'encoding'.pluralize(records.size)}"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: records.map { |r| turbo_stream.remove(r) } +
                             [ turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: flash.now[:notice] }
    end
  end

  def destroy
    record = Current.user.embeddings.find(params[:id])
    record.destroy
    return redirect_to(embeddings_path, notice: "Encoding deleted") if params[:redirect].present?
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Encoding deleted"
        render turbo_stream: [ turbo_stream.remove(record), turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: "Encoding deleted" }
    end
  end

  def destroy_all
    Current.user.embeddings.destroy_all
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "All encodings deleted"
        render turbo_stream: [ turbo_stream.update("embeddings", ""), turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to root_path, notice: "All encodings deleted" }
    end
  end
end
