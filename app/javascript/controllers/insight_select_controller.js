import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "details", "input"]

  onSelectChange(event) {
    if (event.target.value && event.target.value.length > 0) {
      if (this.hasInputTarget) {
        this.inputTargets.forEach((input) => {
          input.value = ""
        })
      }
      if (this.hasDetailsTarget) {
        this.detailsTarget.removeAttribute("open")
      }
    }
  }

  onInputChange(event) {
    if (event.target.value && event.target.value.trim().length > 0) {
      if (this.hasSelectTarget) {
        this.selectTarget.value = ""
      }
    }
  }
}
