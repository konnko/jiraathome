import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {SharedFile} from "./shared_file"
import {LocalTime} from "./local_time"
import {ImagePreview} from "./image_preview"
import {Attachments} from "./media_upload"
import {CardDescription} from "./card_description"

const Board = {
  mounted() {
    this.el.addEventListener("click", event => {
      const card = event.target.closest("[data-card-id]")
      if (!card || event.target.closest("a, button, input, select, textarea, label")) return
      if (this.draggedCardId || Date.now() < (this.ignoreClickUntil || 0)) return
      if (window.getSelection()?.toString()) return
      const button = card.querySelector(".card-content")
      button.focus({preventScroll: true})
      button.click()
    })
    this.el.addEventListener("dragstart", event => {
      const card = event.target.closest("[data-card-id]")
      if (!card) return
      event.dataTransfer.setData("text/plain", card.dataset.cardId)
      event.dataTransfer.effectAllowed = "move"
      this.clearDrag()
      this.draggedCardId = card.dataset.cardId
      this.dragOrigin = {parent: card.parentElement, next: card.nextElementSibling}
      // Let the browser capture its drag preview before turning the source into a placeholder.
      this.dragTimer = setTimeout(() => {
        this.dragTimer = null
        this.markDragSource()
      }, 0)
    })
    this.onDragEnd = () => {
      this.ignoreClickUntil = Date.now() + 150
      // Dropped outside the board: put the card back where it was picked up.
      if (this.dragOrigin) this.animateReorder(() => this.restoreDragOrigin())
      this.clearDrag()
    }
    document.addEventListener("dragend", this.onDragEnd)
    this.el.addEventListener("dragover", event => {
      const column = event.target.closest("[data-status]")
      if (!column || !this.draggedCardId) return
      event.preventDefault()
      event.dataTransfer.dropEffect = "move"
      this.placeDraggedCard(column, event.clientY)
    })
    this.el.addEventListener("drop", event => {
      const card = this.draggedCard()
      const column = card?.closest("[data-status]")
      if (!column) return
      event.preventDefault()
      const index = [...column.querySelectorAll("[data-card-id]")].indexOf(card)
      this.dragOrigin = null
      this.clearDrag()
      this.pushEvent("move", {card_id: card.dataset.cardId, status: column.dataset.status, index})
    })
  },
  draggedCard() {
    return this.draggedCardId && this.el.querySelector(`[data-card-id="${this.draggedCardId}"]`)
  },
  // Moves the dragged card in the DOM to the slot under the pointer, so the drop lands exactly there.
  placeDraggedCard(column, pointerY) {
    const card = this.draggedCard()
    const list = column.querySelector(".column-cards")
    if (!card) return
    // Layout positions (offsetTop) ignore running animation transforms, so cards do not flicker.
    const listTop = list.getBoundingClientRect().top - list.offsetTop
    const before = [...list.querySelectorAll("[data-card-id]")]
      .filter(other => other !== card)
      .find(other => pointerY < listTop + other.offsetTop + other.offsetHeight / 2) || null
    if (card.parentElement === list && card.nextElementSibling === before) return
    this.animateReorder(() => list.insertBefore(card, before))
  },
  // FLIP: remember where cards were, apply the DOM change, then slide them from old to new spots.
  animateReorder(reorder) {
    const cards = [...this.el.querySelectorAll("[data-card-id]")]
    const before = new Map(cards.map(card => [card, card.getBoundingClientRect()]))
    reorder()
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    cards.forEach(card => {
      const from = before.get(card)
      const to = card.getBoundingClientRect()
      const dx = from.left - to.left
      const dy = from.top - to.top
      if (!dx && !dy) return
      card.animate(
        [{transform: `translate(${dx}px, ${dy}px)`}, {transform: "translate(0, 0)"}],
        {duration: 180, easing: "cubic-bezier(0.2, 0, 0, 1)"}
      )
    })
  },
  restoreDragOrigin() {
    const card = this.draggedCard()
    const {parent, next} = this.dragOrigin
    if (card) parent.insertBefore(card, next?.parentElement === parent ? next : null)
    this.dragOrigin = null
  },
  markDragSource() {
    this.draggedCard()?.classList.add("is-drag-placeholder")
  },
  clearDrag() {
    clearTimeout(this.dragTimer)
    this.dragTimer = null
    this.el.querySelectorAll(".is-drag-placeholder").forEach(card => card.classList.remove("is-drag-placeholder"))
    this.draggedCardId = null
    this.dragOrigin = null
  },
  updated() {
    if (this.draggedCardId && !this.dragTimer) this.markDragSource()
  },
  destroyed() {
    this.clearDrag()
    document.removeEventListener("dragend", this.onDragEnd)
  }
}

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: document.querySelector("meta[name='csrf-token']").content},
  hooks: {Board, SharedFile, CardDescription, LocalTime, Attachments, ImagePreview},
})
topbar.config({barColors: {0: "#a2504b"}})
window.addEventListener("phx:page-loading-start", () => topbar.show(300))
window.addEventListener("phx:page-loading-stop", () => topbar.hide())
liveSocket.connect()
window.liveSocket = liveSocket
