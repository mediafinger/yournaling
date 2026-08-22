import { Controller } from "@hotwired/stimulus"

const TRANSPARENT_AFTER_PX = 80

export default class extends Controller {
  connect() {
    this.lastScrollY = window.scrollY

    this.boundCheckScroll = this.checkScroll.bind(this)
    this.boundForceOpaque = this.forceOpaque.bind(this)
    this.boundRecompute = this.recompute.bind(this)

    window.addEventListener("scroll", this.boundCheckScroll, { passive: true })
    this.element.addEventListener("mouseenter", this.boundForceOpaque)
    this.element.addEventListener("mouseleave", this.boundRecompute)
    this.element.addEventListener("touchstart", this.boundForceOpaque, { passive: true })
    this.element.addEventListener("click", this.boundForceOpaque)

    this.checkScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.boundCheckScroll)
    this.element.removeEventListener("mouseenter", this.boundForceOpaque)
    this.element.removeEventListener("mouseleave", this.boundRecompute)
    this.element.removeEventListener("touchstart", this.boundForceOpaque)
    this.element.removeEventListener("click", this.boundForceOpaque)
  }

  // Near the top: always visible. Otherwise: hide while scrolling down,
  // reveal as soon as the user scrolls up again (no need to reach the top).
  checkScroll() {
    const currentY = window.scrollY

    if (currentY <= TRANSPARENT_AFTER_PX) {
      this.setTransparent(false)
    } else if (currentY > this.lastScrollY) {
      this.setTransparent(true)
    } else if (currentY < this.lastScrollY) {
      this.setTransparent(false)
    }

    this.lastScrollY = currentY
  }

  setTransparent(value) {
    this.element.classList.toggle("navbar--transparent", value)
  }

  forceOpaque() {
    this.element.classList.add("navbar--hover")
  }

  recompute() {
    this.element.classList.remove("navbar--hover")
    this.checkScroll()
  }
}
