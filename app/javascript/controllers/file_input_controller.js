import { Controller } from "@hotwired/stimulus"

// Styled file picker: shows the chosen filename(s) and thumbnail previews.
export default class extends Controller {
  static targets = ["input", "names", "previews"]

  preview() {
    const files = Array.from(this.inputTarget.files || [])
    this.namesTarget.textContent = files.length ? files.map((f) => f.name).join(", ") : "no file selected"
    this.previewsTarget.innerHTML = ""
    files.slice(0, 12).forEach((file) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = document.createElement("img")
        img.src = e.target.result
        img.className = "file-field__thumb"
        this.previewsTarget.appendChild(img)
      }
      reader.readAsDataURL(file)
    })
  }
}
