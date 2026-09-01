import { Controller } from "@hotwired/stimulus"

// Progressive enhancement for a <details class="ex-menu">: close on outside
// click, on Escape, and after choosing an item; keep aria-expanded in sync.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    this.onDocClick = this.onDocClick.bind(this)
    this.onKeydown = this.onKeydown.bind(this)
    this.onToggle = this.onToggle.bind(this)
    this.element.addEventListener("toggle", this.onToggle)
    document.addEventListener("click", this.onDocClick)
    document.addEventListener("keydown", this.onKeydown)
    this.syncAria()
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.onToggle)
    document.removeEventListener("click", this.onDocClick)
    document.removeEventListener("keydown", this.onKeydown)
  }

  onToggle() {
    this.syncAria()
  }

  syncAria() {
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", this.element.open ? "true" : "false")
      this.triggerTarget.setAttribute("aria-haspopup", "menu")
    }
  }

  close() {
    this.element.open = false
  }

  onDocClick(event) {
    if (this.element.open && !this.element.contains(event.target)) this.close()
  }

  onKeydown(event) {
    if (event.key === "Escape" && this.element.open) {
      this.close()
      if (this.hasTriggerTarget) this.triggerTarget.focus()
    }
  }

  // click->yui-menu#choose on the panel closes after an item is activated
  choose(event) {
    if (event.target.closest("[role='menuitem']")) this.close()
  }
}
