import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {SharedFile} from "./shared_file"
import {LocalTime} from "./local_time"
import {CardDescription} from "./card_description"

const Board = {
  mounted() {
    this.el.addEventListener("dragstart", event => {
      const card = event.target.closest("[data-card-id]")
      if (!card) return
      event.dataTransfer.setData("text/plain", card.dataset.cardId)
      event.dataTransfer.effectAllowed = "move"
      this.clearDrag()
      this.draggedCardId = card.dataset.cardId
      // Let the browser capture its drag preview before hiding the source.
      this.dragTimer = setTimeout(() => {
        this.dragTimer = null
        this.hideDragSource()
      }, 0)
    })
    this.onDragEnd = () => this.clearDrag()
    document.addEventListener("dragend", this.onDragEnd)
    this.el.addEventListener("dragover", event => {
      if (event.target.closest("[data-status]")) {
        event.preventDefault()
        event.dataTransfer.dropEffect = "move"
      }
    })
    this.el.addEventListener("drop", event => {
      const column = event.target.closest("[data-status]")
      const id = event.dataTransfer.getData("text/plain")
      if (!column || !/^\d+$/.test(id)) return
      event.preventDefault()
      this.clearDrag()
      this.pushEvent("move", {card_id: id, status: column.dataset.status})
    })
  },
  hideDragSource() {
    const card = this.el.querySelector(`[data-card-id="${this.draggedCardId}"]`)
    if (card) card.style.opacity = "0"
  },
  clearDrag() {
    clearTimeout(this.dragTimer)
    this.dragTimer = null
    this.el.querySelectorAll("[data-card-id]").forEach(card => card.style.removeProperty("opacity"))
    this.draggedCardId = null
  },
  updated() {
    if (this.draggedCardId && !this.dragTimer) this.hideDragSource()
  },
  destroyed() {
    this.clearDrag()
    document.removeEventListener("dragend", this.onDragEnd)
  }
}

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: document.querySelector("meta[name='csrf-token']").content},
  hooks: {Board, SharedFile, CardDescription, LocalTime},
})
topbar.config({barColors: {0: "#a2504b"}})
window.addEventListener("phx:page-loading-start", () => topbar.show(300))
window.addEventListener("phx:page-loading-stop", () => topbar.hide())
liveSocket.connect()
window.liveSocket = liveSocket
