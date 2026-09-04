import { Controller } from "@hotwired/stimulus"

// A Chronicle browse card's "Show more" footer link: reveals the entries
// timeline in place, growing the card. No navigation, no server round-trip —
// the timeline is already in the DOM, just [hidden] until toggled.
export default class extends Controller {
  static targets = ["entries", "label"]

  toggle(event) {
    event.preventDefault()

    const collapsed = this.entriesTarget.hidden
    this.entriesTarget.hidden = !collapsed
    this.labelTarget.textContent = collapsed ? "Show less" : "Show more"
  }
}
