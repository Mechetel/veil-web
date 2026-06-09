import { Controller } from "@hotwired/stimulus"

// Gallery upload: reveal the "created with model" select only for stego images.
export default class extends Controller {
  static targets = ["kind", "modelField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isStego = this.kindTarget.value === "stego"
    this.modelFieldTarget.hidden = !isStego
    this.modelFieldTarget.querySelectorAll("select").forEach((el) => (el.disabled = !isStego))
  }
}
