import { Controller } from "@hotwired/stimulus"

// Auto-dismissing toast. Hover pauses the timer; the ✕ dismisses immediately.
export default class extends Controller {
  static values = { delay: { type: Number, default: 6000 } }

  connect() {
    this.startTimer()
    this.element.addEventListener("mouseenter", () => this.clearTimer())
    this.element.addEventListener("mouseleave", () => this.startTimer())
  }

  disconnect() {
    this.clearTimer()
  }

  startTimer() {
    if (this.delayValue <= 0) return
    this.clearTimer()
    this.timer = setTimeout(() => this.dismiss(), this.delayValue)
  }

  clearTimer() {
    if (this.timer) clearTimeout(this.timer)
  }

  dismiss() {
    this.clearTimer()
    this.element.dataset.leaving = "true"
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
    // Fallback if there is no transition (reduced motion).
    setTimeout(() => this.element.remove(), 300)
  }
}
