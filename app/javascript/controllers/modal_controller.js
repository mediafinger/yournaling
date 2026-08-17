import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.handleBackdropClick = this.handleBackdropClick.bind(this)
    if (this.hasDialogTarget) {
      this.dialogTarget.addEventListener("click", this.handleBackdropClick)
    }
  }

  disconnect() {
    if (this.hasDialogTarget) {
      this.dialogTarget.removeEventListener("click", this.handleBackdropClick)
    }
  }

  open(event) {
    if (event) event.preventDefault()
    if (this.hasDialogTarget) {
      if (typeof this.dialogTarget.showModal === "function") {
        this.dialogTarget.showModal()
      } else {
        this.dialogTarget.setAttribute("open", "")
      }
    }
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasDialogTarget) {
      if (typeof this.dialogTarget.close === "function") {
        this.dialogTarget.close()
      } else {
        this.dialogTarget.removeAttribute("open")
      }
    }
  }

  handleBackdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
