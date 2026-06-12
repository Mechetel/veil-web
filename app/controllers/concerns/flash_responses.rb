# Toast helpers for Turbo Stream responses. Toasts are PREPENDED into the
# layout's #flash container (newest on top); each toast self-dismisses after
# 7 s and the stack is pruned to 5 client-side (toast_controller.js).
module FlashResponses
  extend ActiveSupport::Concern

  private

  # Stream that adds the current flash.now contents as new toasts.
  def flash_stream
    turbo_stream.prepend("flash", partial: "shared/flash")
  end

  # Show a form error as a toast WITHOUT navigating away — the user stays on
  # the current page/tab (e.g. the Analyze tab). Non-Turbo requests fall back
  # to a redirect back.
  def flash_error(message, fallback_location: root_path)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        render turbo_stream: flash_stream
      end
      format.html { redirect_back fallback_location: fallback_location, alert: message }
    end
    nil
  end
end
