import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "attachedContainer",
    "dropdown",
    "drawer",
    "drawerTitle",
    "drawerError",
    "drawerFormContainer",
    "locationTemplate",
    "pictureTemplate",
    "storyTemplate",
    "thoughtTemplate",
    "weblinkTemplate",
    "existingLocationTemplate",
    "existingPictureTemplate",
    "existingStoryTemplate",
    "existingThoughtTemplate",
    "existingWeblinkTemplate",
    "locationIdInput",
    "pictureIdInput",
    "thoughtIdInput",
    "weblinkIdInput",
    "locationMenuItem",
    "pictureMenuItem",
    "storyMenuItem",
    "thoughtMenuItem",
    "weblinkMenuItem"
  ]

  static values = {
    mode: { type: String, default: "single" }, // "single" for Memory, "multiple" for Chronicle
    recordName: { type: String, default: "memory" },
    createLocationUrl: String,
    createPictureUrl: String,
    createStoryUrl: String,
    createThoughtUrl: String,
    createWeblinkUrl: String
  }

  connect() {
    this.updateMenuItems()
  }

  openCreate(event) {
    event.preventDefault()
    this.closeDropdown()
    const type = event.currentTarget.dataset.type
    this.showDrawer("create", type)
  }

  openSelect(event) {
    event.preventDefault()
    this.closeDropdown()
    const type = event.currentTarget.dataset.type
    this.showDrawer("select", type)
  }

  closeDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.removeAttribute("open")
    }
  }

  closeDrawer(event) {
    if (event) event.preventDefault()
    if (this.hasDrawerTarget) {
      this.drawerTarget.hidden = true
      this.drawerFormContainerTarget.innerHTML = ""
      this.hideDrawerError()
    }
  }

  showDrawer(action, type) {
    const templateName = action === "create" ? `${type}TemplateTarget` : `existing${this.capitalize(type)}TemplateTarget`
    if (!this[templateName]) return

    const titles = {
      location: action === "create" ? "Create New Location" : "Select Existing Location",
      picture: action === "create" ? "Create New Picture" : "Select Existing Picture",
      story: action === "create" ? "Create New Story" : "Select Existing Story",
      thought: action === "create" ? "Create New Thought" : "Select Existing Thought",
      weblink: action === "create" ? "Create New Weblink" : "Select Existing Weblink"
    }

    this.drawerTitleTarget.textContent = titles[type] || "Add Insight"
    this.drawerFormContainerTarget.innerHTML = this[templateName].innerHTML
    this.hideDrawerError()
    this.drawerTarget.hidden = false
    this.drawerTarget.scrollIntoView({ behavior: "smooth", block: "nearest" })
  }

  showDrawerError(errors) {
    if (!this.hasDrawerErrorTarget) return
    const errorList = Array.isArray(errors) ? errors : [errors]
    this.drawerErrorTarget.innerHTML = `
      <div class="yui-insight-drawer__error" role="alert">
        <strong>Please fix the following:</strong>
        <ul class="yui-stack yui-stack--xs">
          ${errorList.map(err => `<li>${err}</li>`).join("")}
        </ul>
      </div>
    `
    this.drawerErrorTarget.hidden = false
  }

  hideDrawerError() {
    if (this.hasDrawerErrorTarget) {
      this.drawerErrorTarget.innerHTML = ""
      this.drawerErrorTarget.hidden = true
    }
  }

  async submitCreate(event) {
    event.preventDefault()
    this.hideDrawerError()

    const type = event.currentTarget.dataset.type
    const submitBtn = event.currentTarget

    const urlMap = {
      location: this.createLocationUrlValue,
      picture: this.createPictureUrlValue,
      story: this.createStoryUrlValue,
      thought: this.createThoughtUrlValue,
      weblink: this.createWeblinkUrlValue
    }
    const url = urlMap[type]
    if (!url) return

    // The drawer template is a plain <div>, not a <form> (it lives inside the
    // outer record form, and nested forms are dropped by the parser). Collect
    // the drawer's own named fields so we never serialize the outer form.
    const formData = this.collectDrawerFields()
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

    submitBtn.disabled = true
    const originalBtnText = submitBtn.textContent
    submitBtn.textContent = "Creating..."

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken || ""
        },
        body: formData
      })

      const data = await response.json()

      if (response.ok) {
        this.attachInsight(data)
        this.closeDrawer()
      } else {
        const errors = data.errors || ["Failed to create insight"]
        this.showDrawerError(errors)
      }
    } catch (err) {
      this.showDrawerError(`Network error: ${err.message}`)
    } finally {
      submitBtn.disabled = false
      submitBtn.textContent = originalBtnText
    }
  }

  collectDrawerFields() {
    const formData = new FormData()
    const fields = this.drawerFormContainerTarget.querySelectorAll("input[name], select[name], textarea[name]")
    fields.forEach(field => {
      if (field.disabled) return
      if (field.type === "file") {
        if (field.files && field.files.length > 0) formData.append(field.name, field.files[0])
      } else if (field.type === "checkbox" || field.type === "radio") {
        if (field.checked) formData.append(field.name, field.value)
      } else {
        formData.append(field.name, field.value)
      }
    })
    return formData
  }

  selectExisting(event) {
    event.preventDefault()
    this.hideDrawerError()

    const select = this.drawerFormContainerTarget.querySelector("select")
    if (!select || !select.value) {
      this.showDrawerError("Please select an item from the list before adding.")
      return
    }

    const type = select.dataset.type
    const id = select.value
    const name = select.options[select.selectedIndex].text
    const thumbUrl = select.options[select.selectedIndex].dataset.thumbUrl || ""

    this.attachInsight({ id, name, thumb_url: thumbUrl, type })
    this.closeDrawer()
  }

  attachInsight(data) {
    const { id, type } = data

    if (this.modeValue === "single") {
      const inputTarget = `${type}IdInputTarget`
      if (this[inputTarget]) {
        this[inputTarget].value = id
      }
    } else {
      let hiddenInput = this.element.querySelector(`input[data-insight-entry-input="${id}"]`)
      if (!hiddenInput) {
        hiddenInput = document.createElement("input")
        hiddenInput.type = "hidden"
        hiddenInput.name = `${this.recordNameValue}[entry_ids][]`
        hiddenInput.value = id
        hiddenInput.dataset.insightEntryInput = id
        this.element.appendChild(hiddenInput)
      }
    }

    this.renderAttachedChip(data)
    this.updateMenuItems()
  }

  removeInsight(event) {
    event.preventDefault()
    const button = event.currentTarget
    const type = button.dataset.type
    const chip = button.closest("[data-insight-chip]")
    const id = chip?.dataset.id

    if (this.modeValue === "single") {
      const inputTarget = `${type}IdInputTarget`
      if (this[inputTarget]) {
        this[inputTarget].value = ""
      }
    } else if (id) {
      const hiddenInput = this.element.querySelector(`input[data-insight-entry-input="${id}"]`)
      if (hiddenInput) {
        hiddenInput.remove()
      }
    }

    if (chip) {
      chip.remove()
    }

    this.updateMenuItems()
  }

  renderAttachedChip(data) {
    const { id, name, text, thumb_url, type, country_code } = data
    const label = name || text || "Insight"

    // Remove existing chip of same type for single mode
    if (this.modeValue === "single") {
      const existing = this.attachedContainerTarget.querySelector(`[data-insight-chip][data-type="${type}"]`)
      if (existing) existing.remove()
    }

    const icons = {
      location: "📍",
      picture: "🖼",
      story: "📖",
      thought: "💭",
      weblink: "🔗"
    }

    const icon = icons[type] || "📌"
    let mediaSnippet = ""
    if (type === "picture" && thumb_url) {
      mediaSnippet = `<img class="yui-insight-chip__thumb" src="${thumb_url}" alt="" />`
    }

    const chip = document.createElement("div")
    chip.className = "yui-insight-chip"
    chip.dataset.insightChip = "true"
    chip.dataset.type = type
    chip.dataset.id = id

    chip.innerHTML = `
      <span class="yui-insight-chip__label">
        ${mediaSnippet}
        <span><strong>${icon} ${this.capitalize(type)}:&nbsp;</strong>${this.escapeHtml(label)}</span>
      </span>
      <button type="button" class="yui-btn yui-btn--ghost yui-btn--sm yui-insight-chip__remove" data-action="click->insight-manager#removeInsight" data-type="${type}" title="Remove">✕</button>
    `

    this.attachedContainerTarget.appendChild(chip)
  }

  updateMenuItems() {
    if (this.modeValue !== "single") return

    const types = ["location", "picture", "thought", "weblink"]
    types.forEach(type => {
      const inputTarget = `${type}IdInputTarget`
      const menuItemTarget = `${type}MenuItemTarget`
      const isAttached = this[inputTarget] && Boolean(this[inputTarget].value)

      if (this[menuItemTarget]) {
        this[menuItemTarget].hidden = isAttached
      }
    })
  }

  capitalize(str) {
    if (!str) return ""
    return str.charAt(0).toUpperCase() + str.slice(1)
  }

  escapeHtml(str) {
    if (!str) return ""
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}
