import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.boundCheckScroll = this.checkScroll.bind(this)
    window.addEventListener("scroll", this.boundCheckScroll, { passive: true })
    this.checkScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.boundCheckScroll)
  }

  checkScroll() {
    if (!this.hasButtonTarget) return

    if (window.scrollY > 300) {
      this.buttonTarget.classList.add("visible")
    } else {
      this.buttonTarget.classList.remove("visible")
    }
  }

  scrollToTop(event) {
    if (event) event.preventDefault()
    window.scrollTo({
      top: 0,
      behavior: "smooth"
    })
  }
}
