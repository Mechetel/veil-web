# Renders the one confirm dialog (native <dialog>) into the layout's remote_modal
# frame. Generic: the trigger passes title/message/url/method; the dialog button
# performs the real (CSRF-protected, scoped) request. For bulk actions a form_id
# is passed so the confirm button submits that external page form (its checked
# image_ids[]) instead of carrying its own.
class ConfirmationsController < ApplicationController
  def show
    @title         = params[:title].presence || "Are you sure?"
    @message       = params[:message]
    @url           = params[:url]
    @method        = params[:method].presence || "delete"
    @form_id       = params[:form_id].presence
    @confirm_label = params[:confirm_label].presence || "Delete"
    @navigate      = params[:navigate].present?
  end
end
