import * as Y from "yjs"

const storageKey = "jiraathome:shared-file:pending"
const legacyStorageKey = "pochetasks:shared-file:pending"
const encode = bytes => btoa(Array.from(bytes, byte => String.fromCharCode(byte)).join(""))
const decode = value => Uint8Array.from(atob(value), character => character.charCodeAt(0))

// Phoenix transports ordered batches; Yjs merges concurrent edits inside them.
export class FileSync {
  constructor({doc, request, storage, status, saved}) {
    Object.assign(this, {doc, request, storage, status, saved})
    this.pending = []
    this.flight = null
    this.connected = false
    this.generation = 0
    this.deadline = 0
    const draft = storage.getItem(storageKey) || storage.getItem(legacyStorageKey)
    if (draft) {
      const update = decode(draft)
      Y.applyUpdate(doc, update, this)
      this.pending.push(update)
      this.persist()
      storage.removeItem(legacyStorageKey)
    }
    this.onUpdate = (update, origin) => {
      if (origin === this) return
      this.pending.push(update)
      this.persist()
      this.deadline = Date.now() + 1000
      this.schedule()
      this.showStatus()
    }
    doc.on("update", this.onUpdate)
  }

  receive(update) {
    Y.applyUpdate(this.doc, decode(update.data), this)
    if (!this.sequence || update.sequence > this.sequence) {
      this.sequence = update.sequence
      this.saved(update)
    }
  }

  connect(ready = () => {}) {
    const generation = ++this.generation
    this.request("file_sync", {after: 0}, reply => {
      if (generation !== this.generation) return
      reply.updates.forEach(update => this.receive(update))
      this.connected = true
      ready()
      if (this.flight) this.send()
      else this.schedule()
      this.showStatus()
    })
  }

  disconnect() {
    this.generation++
    this.connected = false
    clearTimeout(this.timer)
    this.showStatus()
  }

  schedule() {
    clearTimeout(this.timer)
    if (this.pending.length && this.connected) {
      this.timer = setTimeout(() => this.flush(), Math.max(0, this.deadline - Date.now()))
    }
  }

  flush() {
    if (!this.connected || this.flight || !this.pending.length) return
    this.flight = {token: crypto.randomUUID(), data: encode(Y.mergeUpdates(this.pending))}
    this.pending = []
    this.persist()
    this.send()
  }

  send() {
    const batch = this.flight
    const generation = this.generation
    this.showStatus()
    this.request("file_save", batch, reply => {
      if (generation !== this.generation || this.flight !== batch) return
      if (!reply.ok) {
        this.status("Не удалось сохранить. Правки остаются в этой вкладке.")
        return
      }
      this.receive(reply.update)
      this.flight = null
      this.persist()
      this.schedule()
      this.showStatus()
    })
  }

  persist() {
    const updates = this.flight ? [decode(this.flight.data), ...this.pending] : this.pending
    if (updates.length) this.storage.setItem(storageKey, encode(Y.mergeUpdates(updates)))
    else this.storage.removeItem(storageKey)
  }

  showStatus() {
    this.status(!this.connected ? "Нет связи. Правки остаются в этой вкладке."
      : this.flight ? "Сохраняем…"
      : this.pending.length ? "Есть изменения…"
      : "Все изменения сохранены")
  }

  destroy() {
    this.generation++
    clearTimeout(this.timer)
    this.doc.off("update", this.onUpdate)
  }
}
