import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "position", "handle", "upButton", "downButton"]

  connect() {
    this.updateControlsAndPositions()
  }

  dragstart(event) {
    const item = event.currentTarget.closest("[data-sortable-target='item']")
    if (!item) return

    this.draggedElement = item
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", "") // Required for Firefox
    item.style.opacity = "0.4"
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const targetItem = event.target.closest("[data-sortable-target='item']")
    if (!targetItem || targetItem === this.draggedElement || targetItem.parentElement !== this.element) return

    const rect = targetItem.getBoundingClientRect()
    const midY = rect.top + rect.height / 2

    if (event.clientY < midY) {
      this.element.insertBefore(this.draggedElement, targetItem)
    } else {
      this.element.insertBefore(this.draggedElement, targetItem.nextElementSibling)
    }
  }

  dragend(event) {
    if (this.draggedElement) {
      this.draggedElement.style.opacity = "1"
      this.draggedElement = null
    }
    this.updateControlsAndPositions()
  }

  moveUp(event) {
    event.preventDefault()
    const item = event.currentTarget.closest("[data-sortable-target='item']")
    if (!item) return

    const items = Array.from(this.element.querySelectorAll(":scope > [data-sortable-target='item']"))
    const currentIndex = items.indexOf(item)

    if (currentIndex > 0) {
      const prevItem = items[currentIndex - 1]
      this.element.insertBefore(item, prevItem)
      this.updateControlsAndPositions()
    }
  }

  moveDown(event) {
    event.preventDefault()
    const item = event.currentTarget.closest("[data-sortable-target='item']")
    if (!item) return

    const items = Array.from(this.element.querySelectorAll(":scope > [data-sortable-target='item']"))
    const currentIndex = items.indexOf(item)

    if (currentIndex >= 0 && currentIndex < items.length - 1) {
      const nextItem = items[currentIndex + 1]
      this.element.insertBefore(item, nextItem.nextElementSibling)
      this.updateControlsAndPositions()
    }
  }

  updateControlsAndPositions() {
    const items = Array.from(this.element.querySelectorAll(":scope > [data-sortable-target='item']"))

    items.forEach((item, index) => {
      const positionInput = item.querySelector("[data-sortable-target='position']")
      if (positionInput) {
        positionInput.value = index + 1
      }

      const upButton = item.querySelector("[data-sortable-target='upButton']")
      if (upButton) {
        upButton.disabled = index === 0
      }

      const downButton = item.querySelector("[data-sortable-target='downButton']")
      if (downButton) {
        downButton.disabled = index === items.length - 1
      }
    })
  }
}
