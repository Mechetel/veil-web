import { Controller } from "@hotwired/stimulus"

// Select images for bulk actions. Checkboxes submit via the form they reference
// (form="..._bulk_form"); this tracks selection, reveals the action bar, gates the
// "Set model" button on a chosen model, and clears the selection after a submit.
export default class extends Controller {
  static targets = ["checkbox", "count", "actions", "selectAll", "modelSelect", "setModelBtn"]

  connect() {
    this.refresh()
  }

  toggleAll(event) {
    this.checkboxTargets.forEach((c) => (c.checked = event.target.checked))
    this.refresh()
  }

  refresh() {
    const n = this.checkboxTargets.filter((c) => c.checked).length
    this.countTarget.textContent = `${n} selected`
    this.actionsTarget.hidden = n === 0
    if (this.hasSetModelBtnTarget) {
      this.setModelBtnTarget.disabled = n === 0 || !(this.hasModelSelectTarget && this.modelSelectTarget.value)
    }
  }

  reset() {
    this.checkboxTargets.forEach((c) => (c.checked = false))
    if (this.hasSelectAllTarget) this.selectAllTarget.checked = false
    this.refresh()
  }
}
