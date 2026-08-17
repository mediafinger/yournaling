import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]
  static values = { dialogId: String }

  connect() {
    this.handleBackdropClick = this.handleBackdropClick.bind(this)
    const dialog = this.dialogElement
    if (dialog) {
      dialog.addEventListener("click", this.handleBackdropClick)
    }
  }

  disconnect() {
    const dialog = this.dialogElement
    if (dialog) {
      dialog.removeEventListener("click", this.handleBackdropClick)
    }
  }

  get dialogElement() {
    if (this.hasDialogTarget) {
      return this.dialogTarget
    }
    if (this.hasDialogIdValue) {
      return document.getElementById(this.dialogIdValue)
    }
    return this.element.querySelector("dialog")
  }

  open(event) {
    if (event) event.preventDefault()
    const dialog = this.dialogElement
    if (dialog) {
      if (typeof dialog.showModal === "function") {
        dialog.showModal()
      } else {
        dialog.setAttribute("open", "")
      }
    }
  }

  close(event) {
    if (event) event.preventDefault()
    const dialog = this.dialogElement
    if (dialog) {
      if (typeof dialog.close === "function") {
        dialog.close()
      } else {
        dialog.removeAttribute("open")
      }
    }
  }

  handleBackdropClick(event) {
    const dialog = this.dialogElement
    if (dialog && event.target === dialog) {
      this.close()
    }
  }
}
