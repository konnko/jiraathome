import {Editor, rootCtx, defaultValueCtx, editorViewOptionsCtx, editorViewCtx} from "@milkdown/kit/core"
import {commonmark, toggleStrongCommand, toggleEmphasisCommand, toggleInlineCodeCommand, wrapInHeadingCommand, wrapInBulletListCommand, wrapInOrderedListCommand, wrapInBlockquoteCommand} from "@milkdown/kit/preset/commonmark"
import {gfm} from "@milkdown/kit/preset/gfm"
import {history, undoCommand, redoCommand} from "@milkdown/kit/plugin/history"
import {listener, listenerCtx} from "@milkdown/kit/plugin/listener"
import {getMarkdown, callCommand} from "@milkdown/kit/utils"

export const CardDescription = {
  async mounted() {
    this.input = this.el.querySelector("textarea")
    this.form = this.el.closest("form")
    this.flush = () => {
      if (this.ready) this.input.value = this.editor.action(getMarkdown())
    }
    // Capture submit before LiveView serializes the form. No debounce or autosave here.
    this.form.addEventListener("submit", this.flush, true)
    try {
      this.editor = Editor.make()
        .config(ctx => {
          ctx.set(rootCtx, this.el.querySelector(".card-milkdown"))
          ctx.set(defaultValueCtx, this.input.value)
          ctx.update(editorViewOptionsCtx, options => ({
            ...options,
            attributes: {role: "textbox", "aria-label": "Описание", "aria-multiline": "true", class: "markdown-content"}
          }))
          ctx.get(listenerCtx).markdownUpdated((_ctx, markdown) => {
            if (this.ready && !this.disposed) this.input.value = markdown
          })
        })
        .use(commonmark)
        .use(gfm)
        .use(history)
        .use(listener)
      await this.editor.create()
      if (this.disposed) {
        await this.editor.destroy()
        return
      }
      this.ready = true
      this.input.hidden = true
      this.toolbar = document.createElement("div")
      this.toolbar.className = "card-editor-toolbar"
      this.toolbar.setAttribute("role", "group")
      this.toolbar.setAttribute("aria-label", "Форматирование описания")
      const actions = [
        ["Жирный", "Ж", toggleStrongCommand],
        ["Курсив", "К", toggleEmphasisCommand],
        ["Код", "</>", toggleInlineCodeCommand],
        ["Заголовок", "H2", wrapInHeadingCommand, 2],
        ["Маркированный список", "• Список", wrapInBulletListCommand],
        ["Нумерованный список", "1. Список", wrapInOrderedListCommand],
        ["Цитата", "❞", wrapInBlockquoteCommand],
        ["Отменить", "↶", undoCommand],
        ["Повторить", "↷", redoCommand]
      ]
      for (const [label, text, command, payload] of actions) {
        const button = document.createElement("button")
        button.type = "button"
        button.textContent = text
        button.title = label
        button.setAttribute("aria-label", label)
        const run = () => {
          this.editor.action(callCommand(command.key, payload))
          this.editor.action(ctx => ctx.get(editorViewCtx).focus())
        }
        button.addEventListener("mousedown", event => {
          event.preventDefault()
          run()
        })
        button.addEventListener("click", event => {
          if (event.detail === 0) run()
        })
        this.toolbar.append(button)
      }
      this.el.prepend(this.toolbar)
    } catch (error) {
      console.error("Card description editor failed to initialize", error)
      // Keep the ordinary textarea available if the editor could not load.
    }
  },

  destroyed() {
    this.disposed = true
    this.form.removeEventListener("submit", this.flush, true)
    if (this.ready) this.editor.destroy()
  }
}
