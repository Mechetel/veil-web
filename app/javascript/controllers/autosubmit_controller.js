import { Controller } from "@hotwired/stimulus"

// Submit the controller's form when an input changes (e.g. inline model select).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
