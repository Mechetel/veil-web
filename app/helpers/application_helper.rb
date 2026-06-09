module ApplicationHelper
  # Opens the reusable confirm dialog in the remote_modal frame.
  # Single record: the dialog renders its own button_to(url, method).
  # Bulk: pass form: "<page_form_id>" so the dialog's confirm button submits that
  # external form (with its checked image_ids[]) to url.
  # navigate: true → the confirm submits natively (data-turbo="false") so the
  # controller's redirect performs a real full-page navigation (used on show pages
  # where the delete redirects to the index instead of a Turbo Stream).
  def delete_link(url:, title:, message: nil, label: "Delete", confirm_label: "Delete",
                  form: nil, method: "delete", navigate: false, css: "btn btn--small btn--danger")
    link_to label,
            confirmation_path(url: url, method: method, title: title, message: message,
                              form_id: form, confirm_label: confirm_label, navigate: (navigate ? "1" : nil)),
            data: { turbo_frame: "remote_modal" }, class: css
  end
end
