class AvatarsController < ApplicationController
  def show
    size = (params[:size].presence || 160).to_i.clamp(32, 512)
    png = AvatarGenerator.png(Current.user.display_name, size: size)
    return head :unprocessable_entity if png.nil?

    disposition = params[:disposition] == "attachment" ? "attachment" : "inline"
    send_data png, type: "image/png", disposition: disposition, filename: "avatar.png"
  end
end
