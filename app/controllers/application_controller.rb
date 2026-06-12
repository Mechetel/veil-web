class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  include FlashResponses
  include ResolvesInputImage
  protect_from_forgery with: :exception
end
