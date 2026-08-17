import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  closeOnOutsideClick(event) {
    if (this.element.hasAttribute("open") && !this.element.contains(event.target)) {
      this.element.removeAttribute("open")
    }
  }
}
