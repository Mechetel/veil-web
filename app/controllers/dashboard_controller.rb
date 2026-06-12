class DashboardController < ApplicationController
  TABS = %w[encode decode analyze].freeze

  # The studio tabs are turbo-frame navigations (?tab=...), so each request
  # loads only the active tab's data.
  def index
    @tab = params[:tab].presence_in(TABS) || "encode"
    case @tab
    when "encode"
      @embedding = Embedding.new
      @embeddings_pagy, @embeddings = pagy(Current.user.embeddings.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
    when "decode"
      @decoding = Decoding.new
      @decodings_pagy, @decodings = pagy(Current.user.decodings.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
    when "analyze"
      @analysis = Analysis.new
      @images_pagy, @images = pagy(Image.analyzed_for(Current.user).with_attached_file,
                                   limit: 8, page_key: "analyses_page")
    end
  end
end
