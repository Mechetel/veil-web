import { Controller } from "@hotwired/stimulus"

// The one and only modal: a native <dialog> rendered (server-side) into the
// shared `remote_modal` turbo-frame. Opens on connect; dismisses on Cancel,
// backdrop click, Esc, or a successful form submission (the confirmed action).
// Closing removes the dialog from the frame — no server round-trip (no
// clear_modal) needed.
export default class extends Controller {
  connect() {
    if (!this.element.open) this.element.showModal()
  }

  // Cancel button / programmatic dismiss.
  close(event) {
    if (event) event.preventDefault()
    this.element.close()
  }

  // Click on the dialog itself is a click on the ::backdrop (its content sits in
  // .modal__box); a click inside the box targets the box, not the dialog.
  backdrop(event) {
    if (event.target === this.element) this.element.close()
  }

  // The confirmed action (delete / convert / bulk) finished successfully.
  submitEnd(event) {
    if (event.detail?.success) this.element.close()
  }

  // Native `close` event (fires for Esc, backdrop, and close()) — drop the
  // dialog out of the frame so it leaves no residue.
  cleanup() {
    this.element.remove()
  }
}
