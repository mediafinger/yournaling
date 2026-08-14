import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.validate()
  }

  validate() {
    const query = this.inputTarget.value.trim()
    this.submitTarget.disabled = query.length < 3
  }
}
