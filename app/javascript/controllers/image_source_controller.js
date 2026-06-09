import { Controller } from "@hotwired/stimulus"

// Toggle upload vs "from my images", and preview the chosen image either way.
// Only the active panel's inputs are enabled so exactly one of image / image_id submits.
export default class extends Controller {
  static targets = ["upload", "gallery", "fileInput", "preview", "previewWrap"]

  connect() {
    this.toggle(this.galleryTarget, false)
  }

  choose(event) {
    const mode = event.target.value
    this.toggle(this.uploadTarget, mode === "upload")
    this.toggle(this.galleryTarget, mode === "gallery")
    this.clearPreview()
  }

  toggle(panel, active) {
    panel.hidden = !active
    panel.querySelectorAll("input, select").forEach((el) => (el.disabled = !active))
  }

  previewFile() {
    const file = this.fileInputTarget.files[0]
    if (!file) return this.clearPreview()
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
}
