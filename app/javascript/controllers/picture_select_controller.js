import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "summary", "hiddenInput", "fileInput", "filePreview"]

  selectOption(event) {
    event.preventDefault()
    const link = event.currentTarget
    const pictureId = link.dataset.pictureId || ""
    const pictureName = link.dataset.pictureName || "Choose an existing picture..."
    const previewUrl = link.dataset.previewUrl || ""

    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = pictureId
    }

    if (this.hasSummaryTarget) {
      if (previewUrl && pictureId) {
        this.summaryTarget.innerHTML = `
          <span style="display: flex; align-items: center; gap: 0.75rem;">
            <img src="${previewUrl}" style="width: 40px; height: 30px; object-fit: cover; border-radius: 3px;" alt="" />
            <span>${pictureName}</span>
          </span>
        `
      } else {
        this.summaryTarget.textContent = pictureName
      }
    }

    if (this.hasDropdownTarget) {
      this.dropdownTarget.removeAttribute("open")
    }
  }

  updateFilePreview() {
    if (!this.hasFileInputTarget || !this.hasFilePreviewTarget) return

    const file = this.fileInputTarget.files ? this.fileInputTarget.files[0] : null

    if (file && file.type.startsWith("image/")) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.filePreviewTarget.src = e.target.result
        this.filePreviewTarget.style.display = "block"
      }
      reader.readAsDataURL(file)
    } else {
      this.filePreviewTarget.src = ""
      this.filePreviewTarget.style.display = "none"
    }
  }
}
