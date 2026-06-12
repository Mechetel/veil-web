import { Controller } from "@hotwired/stimulus"

// Toggle upload / "from my images" / defaults, and preview the chosen image.
// Only the active panel's inputs are enabled so exactly one of
// image / image_id / default_image submits. Uploads are validated client-side
// (PNG/JPG ≤ 2 MB — mirrors the server-side Image model validation).
const ALLOWED_TYPES = ["image/png", "image/jpeg"]
const MAX_SIZE = 2 * 1024 * 1024

export default class extends Controller {
  static targets = ["upload", "gallery", "defaults", "fileInput", "preview", "previewWrap", "error"]

  connect() {
    this.toggle(this.galleryTarget, false)
    if (this.hasDefaultsTarget) this.toggle(this.defaultsTarget, false)
  }

  choose(event) {
    const mode = event.target.value
    this.toggle(this.uploadTarget, mode === "upload")
    this.toggle(this.galleryTarget, mode === "gallery")
    if (this.hasDefaultsTarget) this.toggle(this.defaultsTarget, mode === "defaults")
    this.clearPreview()
    this.hideError()
  }

  toggle(panel, active) {
    panel.hidden = !active
    panel.querySelectorAll("input, select").forEach((el) => (el.disabled = !active))
  }

  previewFile() {
    const file = this.fileInputTarget.files[0]
    if (!file) return this.clearPreview()

    if (!ALLOWED_TYPES.includes(file.type) || file.size > MAX_SIZE) {
      this.fileInputTarget.value = ""
      this.clearPreview()
      this.showError(`"${file.name}" rejected — only PNG/JPG up to 2 MB.`)
      return
    }

    this.hideError()
    const reader = new FileReader()
    reader.onload = (e) => this.showPreview(e.target.result)
    reader.readAsDataURL(file)
  }

  previewSelected(event) {
    this.showPreview(event.target.dataset.previewUrl)
    this.element
      .querySelectorAll(".picker__item")
      .forEach((el) => el.classList.remove("is-selected"))
    event.target.closest(".picker__item")?.classList.add("is-selected")

    // If this image knows the model it was made with, prefill the form's model select.
    const modelKey = event.target.dataset.modelKey
    if (modelKey) {
      const select = this.element.closest("form")?.querySelector("select[name='model_key']")
      if (select && [...select.options].some((o) => o.value === modelKey)) {
        select.value = modelKey
      }
    }
  }

  showPreview(src) {
    this.previewTarget.src = src
    this.previewWrapTarget.hidden = false
  }

  clearPreview() {
    this.previewTarget.removeAttribute("src")
    this.previewWrapTarget.hidden = true
  }

  showError(text) {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = text
    this.errorTarget.hidden = false
  }

  hideError() {
    if (this.hasErrorTarget) this.errorTarget.hidden = true
  }
}
