import { Controller } from "@hotwired/stimulus"

// Native <dialog> modal: open/close + light-dismiss (click the backdrop).
// Escape and focus handling come from <dialog> itself.
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.onDialogClick = this.onDialogClick.bind(this)
    this.dialog?.addEventListener("click", this.onDialogClick)
  }

  disconnect() {
    this.dialog?.removeEventListener("click", this.onDialogClick)
  }

  get dialog() {
    return this.hasDialogTarget ? this.dialogTarget : this.element.querySelector("dialog")
  }

  open(event) {
    event?.preventDefault()
    const d = this.dialog
    if (d?.showModal) d.showModal()
    else d?.setAttribute("open", "")
  }

  close(event) {
    event?.preventDefault()
    const d = this.dialog
    if (d?.close) d.close()
    else d?.removeAttribute("open")
  }

  // Clicking the ::backdrop registers as a click on the <dialog> itself.
  onDialogClick(event) {
    const panel = this.dialog.querySelector(".ex-modal__panel")
    if (panel && !panel.contains(event.target)) this.close()
  }
}
