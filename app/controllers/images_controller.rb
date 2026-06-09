class ImagesController < ApplicationController
  before_action :set_image, only: %i[show update destroy convert]

  def index
    @covers_pagy, @covers = pagy(Current.user.images.cover.gallery.with_attached_file, limit: 8, page_key: "cover_page")
    @stegos_pagy, @stegos = pagy(Current.user.images.stego.gallery.with_attached_file, limit: 8, page_key: "stego_page")
    respond_to do |format|
      format.html
      format.turbo_stream # load-more
    end
  end

  def show; end

  # Add one or more images. kind = cover|stego; for stego a model_key may be stored.
  def create
    files = Array(params[:images]).compact_blank
    files << params[:image] if params[:image].present?
    return redirect_to(images_path, alert: "Choose at least one image.") if files.empty?

    kind      = params[:kind].to_s.presence_in(%w[cover stego]) || "cover"
    model_key = params[:model_key].presence
    metadata  = (kind == "stego" && model_key) ? { "model_key" => model_key } : {}

    created = []
    skipped = 0
    files.each do |file|
      img = Current.user.images.new(kind: kind, origin: :uploaded, metadata: metadata)
      img.file.attach(file)
      img.save ? (created << img) : (skipped += 1)
    end
    flash.now[:notice] = "#{created.size} #{'image'.pluralize(created.size)} added" +
                         (skipped.positive? ? " · #{skipped} skipped (gallery full)" : "")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: created.reverse.map { |img| turbo_stream.prepend("#{kind}s", partial: "images/image", locals: { image: img }) } +
                             [ turbo_stream.replace("#{kind}_upload", partial: "images/#{kind}_upload"),
                               turbo_stream.replace("#{kind}_count", partial: "images/count", locals: { kind: kind }),
                               turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to images_path, notice: flash.now[:notice] }
    end
  end

  # Inline model edit, or convert cover→stego (kind + model_key).
  def update
    was_kind = @image.kind
    @image.kind = params[:kind] if params[:kind].present?
    @image.metadata = (@image.metadata || {}).merge("model_key" => params[:model_key].presence) if params.key?(:model_key)

    if @image.save
      respond_to do |format|
        format.turbo_stream do
          card = if @image.kind != was_kind
            [ turbo_stream.remove(@image), turbo_stream.prepend("#{@image.kind}s", partial: "images/image", locals: { image: @image }) ]
          else
            [ turbo_stream.replace(@image, partial: "images/image", locals: { image: @image }) ]
          end
          flash.now[:notice] = was_kind == @image.kind ? "Image updated" : "Converted to #{@image.kind}"
          render turbo_stream: card + count_streams + [ turbo_stream.update("flash", partial: "shared/flash") ]
        end
        format.html { redirect_to images_path, notice: "Image updated" }
      end
    else
      flash.now[:alert] = @image.errors.full_messages.to_sentence
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash") }
        format.html { redirect_to images_path, alert: flash.now[:alert] }
      end
    end
  end

  # Modal (remote_modal frame) for converting a cover to stego.
  def convert
    render layout: false
  end

  def destroy
    kind = @image.kind
    @image.destroy
    return redirect_to(images_path, notice: "Image deleted") if params[:redirect].present?
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Image deleted"
        render turbo_stream: [
          turbo_stream.remove(@image),
          turbo_stream.replace("#{kind}_count", partial: "images/count", locals: { kind: kind }),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html { redirect_to images_path, notice: "Image deleted" }
    end
  end

  def destroy_all
    kind = params[:kind].to_s.presence_in(%w[cover stego]) || "cover"
    Current.user.images.where(kind: kind).destroy_all
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "All #{kind} images deleted"
        render turbo_stream: [
          turbo_stream.update("#{kind}s", ""),
          turbo_stream.replace("#{kind}_count", partial: "images/count", locals: { kind: kind }),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html { redirect_to images_path, notice: "All #{kind} images deleted" }
    end
  end

  def bulk_destroy
    images = Current.user.images.where(id: Array(params[:image_ids]).compact_blank).to_a
    images.each(&:destroy)
    flash.now[:notice] = "Deleted #{images.size} #{'image'.pluralize(images.size)}"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: images.map { |img| turbo_stream.remove(img) } + count_streams + [ turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to images_path, notice: flash.now[:notice] }
    end
  end

  def bulk_update_model
    images = Current.user.images.stego.where(id: Array(params[:image_ids]).compact_blank).to_a
    images.each { |img| img.update(metadata: (img.metadata || {}).merge("model_key" => params[:model_key].presence)) }
    flash.now[:notice] = "Updated #{images.size} #{'image'.pluralize(images.size)}"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: images.map { |img| turbo_stream.replace(img, partial: "images/image", locals: { image: img }) } + [ turbo_stream.update("flash", partial: "shared/flash") ]
      end
      format.html { redirect_to images_path, notice: flash.now[:notice] }
    end
  end

  private

  def set_image
    @image = Current.user.images.find(params[:id])
  end

  def count_streams
    %w[cover stego].map { |k| turbo_stream.replace("#{k}_count", partial: "images/count", locals: { kind: k }) }
  end
end
