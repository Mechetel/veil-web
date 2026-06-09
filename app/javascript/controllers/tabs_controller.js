import { Controller } from "@hotwired/stimulus"

// Simple client-side tab switcher for the Encode/Decode/Analyze studio.
export default class extends Controller {
  static targets = ["btn", "panel"]

  show(event) {
    const panel = event.currentTarget.dataset.panel
    this.panelTargets.forEach((p) => (p.hidden = p.dataset.panel !== panel))
    this.btnTargets.forEach((b) =>
      b.classList.toggle("is-active", b.dataset.panel === panel)
    )
  }
}
