import {createCrepe} from "./crepe_editor"
import {editorViewOptionsCtx} from "@milkdown/kit/core"
import {history} from "@milkdown/kit/plugin/history"
import {collab, collabServiceCtx} from "@milkdown/plugin-collab"
import "@milkdown/crepe/theme/common/style.css"
import "@milkdown/crepe/theme/frame.css"
import * as Y from "yjs"
import {formatLocalTime} from "./local_time"
import {FileSync} from "./file_sync"

export const SharedFile = {
  mounted() {
    this.doc = new Y.Doc()
    this.sync = new FileSync({
      doc: this.doc,
      request: (event, payload, callback) => this.pushEvent(event, payload, callback),
      storage: window.sessionStorage,
      status: text => { this.el.querySelector("#file-status").textContent = text },
      saved: update => {
        this.el.querySelector("#file-saved-at").textContent = `${update.author} · ${formatLocalTime(update.saved_at)}`
      }
    })
    this.handleEvent("file_update", update => this.sync.receive(update))
    this.sync.connect(() => this.createEditor())
  },

  async createEditor() {
    if (this.creating || this.editor || this.disposed) return
    this.creating = true
    try {
      const crepe = createCrepe(this.el.querySelector("#milkdown-editor"))
      // Collaborative undo must track only this user's edits.
      await crepe.editor.remove(history)
      crepe.editor
        .config(ctx => {
          ctx.update(editorViewOptionsCtx, options => ({
            ...options,
            attributes: {role: "textbox", "aria-label": "Текст общего файла", "aria-multiline": "true"}
          }))
        })
        .use(collab)
      await crepe.create()
      if (this.disposed) {
        await crepe.destroy()
        return
      }
      this.editor = crepe.editor
      this.editor.action(ctx => ctx.get(collabServiceCtx).bindDoc(this.doc).connect())
    } catch (error) {
      this.el.querySelector("#file-status").textContent = "Не удалось загрузить редактор. Обновите страницу."
      console.error("Milkdown initialization failed", error)
    } finally {
      this.creating = false
    }
  },

  disconnected() { this.sync.disconnect() },
  reconnected() { this.sync.connect(() => { if (!this.editor) this.createEditor() }) },
  destroyed() {
    this.disposed = true
    this.sync.destroy()
    Promise.resolve(this.editor?.destroy()).finally(() => this.doc.destroy())
  }
}
