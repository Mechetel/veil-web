import { Controller } from "@hotwired/stimulus"

// Styled file picker: shows the chosen filename(s) and thumbnail previews.
// Rejects files that are not PNG/JPG or exceed 2 MB (mirrors the server-side
// validation on the Image model — keep the two in sync).
const ALLOWED_TYPES = ["image/png", "image/jpeg"]
const MAX_SIZE = 2 * 1024 * 1024

export default class extends Controller {
  static targets = ["input", "names", "previews"]

  preview() {
    const files = Array.from(this.inputTarget.files || [])
    this.previewsTarget.innerHTML = ""

    const rejected = files.filter((f) => !ALLOWED_TYPES.includes(f.type) || f.size > MAX_SIZE)
    if (rejected.length) {
      this.inputTarget.value = ""
      this.namesTarget.textContent =
        `Only PNG/JPG up to 2 MB — rejected: ${rejected.map((f) => f.name).join(", ")}`
      this.namesTarget.classList.add("error")
      return
    }

    this.namesTarget.classList.remove("error")
    this.namesTarget.textContent = files.length ? files.map((f) => f.name).join(", ") : "no file selected"
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
