import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "container", "topSentinel"]
  static values = {
    since: String,
    checkUrl: String,
    loadUrl: String,
    pollInterval: { type: Number, default: 5000 }
  }

  connect() {
    this.hasNewerPosts = false
    this.loading = false

    if (this.hasPollIntervalValue && this.pollIntervalValue > 0) {
      this.timer = setInterval(() => this.checkNewer(), this.pollIntervalValue)
    }

    if (this.hasTopSentinelTarget && "IntersectionObserver" in window) {
      this.observer = new IntersectionObserver((entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting && this.hasNewerPosts) {
            this.loadNewer()
          }
        }
      }, { threshold: 0.1 })
      this.observer.observe(this.topSentinelTarget)
    }

    this.onScroll = () => {
      if (window.scrollY <= 10 && this.hasNewerPosts) {
        this.loadNewer()
      }
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
    if (this.observer) this.observer.disconnect()
    if (this.onScroll) window.removeEventListener("scroll", this.onScroll)
  }

  async checkNewer() {
    if (this.loading || !this.hasCheckUrlValue || !this.hasSinceValue || !this.sinceValue) return

    try {
      const url = `${this.checkUrlValue}?since=${encodeURIComponent(this.sinceValue)}`
      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) return

      const data = await response.json()
      if (data.count > 0) {
        this.hasNewerPosts = true
        if (this.hasBannerTarget) {
          this.bannerTarget.hidden = false
          this.bannerTarget.style.display = "block"
        }
        if (window.scrollY <= 10) {
          this.loadNewer()
        }
      }
    } catch (e) {
      // Ignore network errors during polling
    }
  }

  async loadNewer() {
    if (this.loading || !this.hasLoadUrlValue || !this.hasSinceValue || !this.sinceValue) return

    this.loading = true
    try {
      const url = `${this.loadUrlValue}?since=${encodeURIComponent(this.sinceValue)}`
      const response = await fetch(url, {
        headers: { "Accept": "text/html" }
      })
      if (!response.ok) return

      const html = await response.text()
      const temp = document.createElement("div")
      temp.innerHTML = html

      const wrapper = temp.querySelector("[data-newest-at]")
      if (wrapper) {
        const nextSince = wrapper.getAttribute("data-newest-at")
        if (nextSince) {
          this.sinceValue = nextSince
        }
        if (this.hasContainerTarget) {
          this.containerTarget.insertAdjacentHTML("afterbegin", wrapper.innerHTML)
        }
      }

      this.hasNewerPosts = false
      if (this.hasBannerTarget) {
        this.bannerTarget.hidden = true
        this.bannerTarget.style.display = "none"
      }
    } finally {
      this.loading = false
    }
  }
}
