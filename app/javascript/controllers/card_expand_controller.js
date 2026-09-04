import { Controller } from "@hotwired/stimulus"

// A Chronicle browse card's "Show more" footer link. The card's content is
// already fully rendered — collapsed just means the body is clipped to a max
// height and faded out (.yui-chronicle-card--collapsed). Toggling that class
// lifts the clip in place: no navigation, no server round-trip.
export default class extends Controller {
  static targets = ["label"]

  static classes = ["collapsed"]

  toggle(event) {
    event.preventDefault()

    const collapsed = this.element.classList.toggle(this.collapsedClassName)
    this.labelTarget.textContent = collapsed ? "Show more" : "Show less"
  }

  // Falls back to the card's own modifier when no data-card-expand-collapsed-class
  // is declared on the element, which is the only way it is used today.
  get collapsedClassName() {
    return this.hasCollapsedClass ? this.collapsedClass : "yui-chronicle-card--collapsed"
  }
}
