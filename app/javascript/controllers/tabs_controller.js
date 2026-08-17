import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { activeIndex: { type: Number, default: 0 } }

  connect() {
    this.showActiveTab()
  }

  select(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.tabIndex, 10)
    this.activeIndexValue = index
    this.showActiveTab()
  }

  showActiveTab() {
    this.tabTargets.forEach((tab, index) => {
      const isActive = index === this.activeIndexValue
      tab.setAttribute("aria-selected", isActive ? "true" : "false")
      if (isActive) {
        tab.classList.remove("outline", "secondary")
      } else {
        tab.classList.add("outline", "secondary")
      }
    })

    this.panelTargets.forEach((panel, index) => {
      const isActive = index === this.activeIndexValue
      panel.style.display = isActive ? "block" : "none"
      panel.hidden = !isActive
    })
  }
}
