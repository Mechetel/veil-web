class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  protect_from_forgery with: :exception

  private

  # Resolve the input image for a task: an existing gallery Image (image_id) or a
  # freshly uploaded file (image). Returns nil when neither is provided.
  def find_or_build_input_image(default_kind: :cover)
    if params[:image_id].present?
      Current.user.images.find(params[:image_id])
    elsif params[:image].present?
      image = Current.user.images.new(kind: default_kind, origin: :uploaded)
      image.file.attach(params[:image])
      image.save
      image.persisted? ? image : nil
    end
  end
end
