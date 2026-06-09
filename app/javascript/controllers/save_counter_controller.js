import { Controller } from "@hotwired/stimulus"

// Select encode results for the stego gallery — mirrors the gallery bulk bar.
// Shows "N selected", puts the count in the Save button ("Save N to gallery"),
// and disables Save when the selection would push the gallery past its cap
// (current stego count + selected > limit). The whole bar hides when there is
// nothing selectable (no succeeded-but-unsaved encodings on the page).
export default class extends Controller {
  static targets = ["bar", "count", "submit", "selectAll", "actions", "checkbox"]
  static values = { current: Number, limit: Number }

  connect() {
    this.refresh()
  }

  toggleAll(event) {
    this.checkboxTargets.forEach((c) => (c.checked = event.target.checked))
    this.refresh()
  }

  reset() {
    this.checkboxTargets.forEach((c) => (c.checked = false))
    if (this.hasSelectAllTarget) this.selectAllTarget.checked = false
    this.refresh()
  }

  refresh() {
    const boxes = this.checkboxTargets
    this.barTarget.hidden = boxes.length === 0

    const checked = boxes.filter((c) => c.checked).length
    const over = this.currentValue + checked > this.limitValue

    this.countTarget.textContent = over
      ? `${checked} selected · gallery full (max ${this.limitValue})`
      : `${checked} selected`
    this.countTarget.classList.toggle("is-over", over)

    if (this.hasActionsTarget) this.actionsTarget.hidden = checked === 0
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = checked === 0 || over
      this.submitTarget.value = checked > 0 ? `Save ${checked} to gallery` : "Save to gallery"
    }
    if (this.hasSelectAllTarget) this.selectAllTarget.checked = boxes.length > 0 && checked === boxes.length
  }
}
