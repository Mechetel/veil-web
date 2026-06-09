class DashboardController < ApplicationController
  def index
    @embedding = Embedding.new
    @decoding  = Decoding.new
    @analysis  = Analysis.new
    @embeddings_pagy, @embeddings = pagy(Current.user.embeddings.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
    @decodings_pagy,  @decodings  = pagy(Current.user.decodings.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
    @analyses_pagy,   @analyses   = pagy(Current.user.analyses.recent.includes(input_image: { file_attachment: :blob }), limit: 20)
  end
end
