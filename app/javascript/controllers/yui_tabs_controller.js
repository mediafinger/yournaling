import { Controller } from "@hotwired/stimulus"

// ARIA tab set: toggle aria-selected / hidden, roving tabindex, arrow keys.
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { activeIndex: { type: Number, default: 0 } }

  connect() {
    this.show()
  }

  select(event) {
    event.preventDefault()
    this.activeIndexValue = parseInt(event.currentTarget.dataset.tabIndex, 10)
    this.show()
  }

  onKeydown(event) {
    const keys = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }
    const step = keys[event.key]
    if (!step) return
    event.preventDefault()
    const count = this.tabTargets.length
    this.activeIndexValue = (this.activeIndexValue + step + count) % count
    this.show()
    this.tabTargets[this.activeIndexValue]?.focus()
  }

  show() {
    const active = this.activeIndexValue
    this.tabTargets.forEach((tab, i) => {
      const on = i === active
      tab.setAttribute("aria-selected", on ? "true" : "false")
      tab.setAttribute("tabindex", on ? "0" : "-1")
      tab.classList.toggle("ex-tabs__tab--active", on)
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== active
    })
  }
}
