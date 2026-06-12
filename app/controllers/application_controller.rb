class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  protect_from_forgery with: :exception

  private

  # Resolve the input image for a task: an existing gallery Image (image_id), a
  # freshly uploaded file (image), or a shared default (default_image — copied
  # into the user's gallery). Returns nil when nothing was provided; returns an
  # UNSAVED record when validation failed (callers surface its errors).
  def find_or_build_input_image(default_kind: :cover)
    if params[:image_id].present?
      Current.user.images.find(params[:image_id])
    elsif params[:image].present?
      image = Current.user.images.new(kind: default_kind, origin: :uploaded)
      image.file.attach(params[:image])
      image.save
      image
    elsif params[:default_image].present?
      build_stock_image(params[:default_image], default_kind)
    end
  end

  def build_stock_image(name, kind)
    path = DefaultImages.path_for(name)
    return nil unless path

    image = Current.user.images.new(kind: kind, origin: :stock)
    image.file.attach(io: File.open(path), filename: name,
                      content_type: DefaultImages.content_type_for(name))
    image.save
    image
  end

  # Shared guard for the three task controllers: redirects with a useful alert
  # when no input was chosen or the upload failed validation.
  def require_input_image(input, fallback_message)
    return input if input&.persisted?

    alert = input ? input.errors.full_messages.to_sentence : fallback_message
    redirect_to(root_path, alert: alert)
    nil
  end
end
