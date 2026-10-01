import {createCrepe} from "./crepe_editor"
import {uploadPlugin} from "@milkdown/kit/plugin/upload"
import {defaultValueCtx, editorViewOptionsCtx} from "@milkdown/kit/core"

export const CardDescription = {
  async mounted() {
    this.input = this.el.querySelector("textarea")
    this.form = this.el.closest("form")
    this.flush = () => {
      if (this.ready) this.input.value = this.crepe.getMarkdown()
    }
    // Capture submit before LiveView serializes the form. No debounce or autosave here.
    this.form.addEventListener("submit", this.flush, true)
    try {
      this.crepe = createCrepe(this.el.querySelector(".card-milkdown"), {
        placeholder: "Детали, мысли, ссылки… Введите / для выбора блока",
        features: {latex: false, "image-block": false}
      })
      await this.crepe.editor.remove(uploadPlugin)
      this.crepe.editor.config(ctx => {
        ctx.set(defaultValueCtx, this.input.value)
        ctx.update(editorViewOptionsCtx, options => ({
          ...options,
          attributes: {role: "textbox", "aria-label": "Описание", "aria-multiline": "true"}
        }))
      })
      this.crepe.on(listener => listener.markdownUpdated((_ctx, markdown) => {
        if (this.ready && !this.disposed) this.input.value = markdown
      }))
      await this.crepe.create()
      if (this.disposed) {
        await this.crepe.destroy()
        return
      }
      this.ready = true
      this.input.hidden = true
    } catch (error) {
      console.error("Card description editor failed to initialize", error)
      // Keep the ordinary textarea available if the editor could not load.
    }
  },

  destroyed() {
    this.disposed = true
    this.form.removeEventListener("submit", this.flush, true)
    if (this.ready) this.crepe.destroy()
  }
}
