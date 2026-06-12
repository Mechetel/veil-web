import { Controller } from "@hotwired/stimulus"

// One flash toast: auto-dismisses after `timeout` ms (default 7 s), dismisses
// on the × button, and on arrival prunes the stack so at most `MAX` toasts are
// visible (newest are prepended on top, so extras are dropped from the bottom).
const MAX = 5

export default class extends Controller {
  static values = { timeout: { type: Number, default: 7000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
    this.prune()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.remove()
  }

  prune() {
    const container = this.element.parentElement
    if (!container) return
    Array.from(container.children).slice(MAX).forEach((el) => el.remove())
  }
}
