import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="drug-autocomplete"
export default class extends Controller {
  static targets = ["input", "results", "hiddenRxcui"]
  static values = {
    url: { type: String, default: "/api/v1/drugs/autocomplete" }
  }

  connect() {
    this.timeout = null
    this.selectedIndex = -1
    
    // Close dropdown when clicking outside
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.boundHandleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleClickOutside)
    this.clearTimeout()
  }

  search() {
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.hideResults()
      return
    }

    this.clearTimeout()
    this.timeout = setTimeout(() => this.fetchResults(query), 300)
  }

  async fetchResults(query) {
    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("query", query)

      const response = await fetch(url)
      if (!response.ok) throw new Error("Network response was not ok")

      const data = await response.json()
      this.displayResults(data)
    } catch (error) {
      console.error("Drug autocomplete error:", error)
      this.hideResults()
    }
  }

  displayResults(results) {
    if (!results || results.length === 0) {
      this.hideResults()
      return
    }

    this.resultsTarget.innerHTML = results
      .map((drug, index) => 
        `<div class="autocomplete-item" data-index="${index}" data-action="click->drug-autocomplete#select mouseenter->drug-autocomplete#highlight">
          ${this.escapeHtml(drug.name)}
        </div>`
      )
      .join("")

    this.selectedIndex = -1
    this.resultsTarget.classList.remove("d-none")
  }

  hideResults() {
    this.resultsTarget.classList.add("d-none")
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
  }

  select(event) {
    const item = event.currentTarget
    const drugName = item.textContent.trim()
    
    this.inputTarget.value = drugName
    this.hideResults()
    this.inputTarget.focus()
  }

  highlight(event) {
    this.clearHighlight()
    event.currentTarget.classList.add("active")
    this.selectedIndex = parseInt(event.currentTarget.dataset.index)
  }

  clearHighlight() {
    this.resultsTarget.querySelectorAll(".autocomplete-item").forEach(item => {
      item.classList.remove("active")
    })
  }

  navigate(event) {
    const items = this.resultsTarget.querySelectorAll(".autocomplete-item")
    if (items.length === 0) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.highlightIndex(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.highlightIndex(items)
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && this.selectedIndex < items.length) {
          items[this.selectedIndex].click()
        }
        break
      case "Escape":
        this.hideResults()
        break
    }
  }

  highlightIndex(items) {
    this.clearHighlight()
    if (this.selectedIndex >= 0 && this.selectedIndex < items.length) {
      items[this.selectedIndex].classList.add("active")
      items[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  clearTimeout() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
