export async function uploadMedia(file) {
  if (file.size > 20 * 1024 * 1024) throw new Error("Максимальный размер файла — 20 МБ")
  const body = new FormData()
  body.append("file", file)
  const response = await fetch("/media", {
    method: "POST", body, credentials: "same-origin",
    headers: {"x-csrf-token": document.querySelector('meta[name="csrf-token"]').content, Accept: "application/json"}
  })
  if (!response.ok) throw new Error(response.status === 413 ? "Максимальный размер файла — 20 МБ" : "Не удалось загрузить файл. Проверьте соединение и повторите.")
  return response.json()
}

export const Attachments = {
  mounted() {
    const picker = this.el.querySelector('input[type="file"]')
    const list = this.el.querySelector('.attachment-list')
    const status = this.el.querySelector('.attachment-status')
    const form = this.el.closest('form')
    this.preventPending = event => {
      if (this.pending) {
        event.preventDefault()
        event.stopImmediatePropagation()
        status.textContent = "Дождитесь завершения загрузки"
      }
    }
    form.addEventListener('submit', this.preventPending, true)
    this.form = form
    this.el.addEventListener('click', event => {
      if (event.target.closest('[data-remove-attachment]')) event.target.closest('.attachment-row').remove()
    })
    picker.addEventListener('change', async () => {
      this.pending = true
      picker.disabled = true
      status.textContent = "Загружаем…"
      const errors = []
      for (const file of picker.files) {
        try {
          const media = await uploadMedia(file)
          if (this.disposed) break
          const row = document.createElement('div')
          row.className = 'attachment-row'
          const input = document.createElement('input')
          input.type = 'hidden'; input.name = 'card[attachment_ids][]'; input.value = media.id
          const link = document.createElement('a')
          if (media.type.startsWith('image/')) link.dataset.imagePreview = 'true'
          link.href = media.url; link.textContent = media.name; link.target = '_blank'; link.rel = 'noopener'
          const remove = document.createElement('button')
          remove.type = 'button'; remove.textContent = '✕'; remove.dataset.removeAttachment = ''
          remove.setAttribute('aria-label', `Убрать ${media.name}`)
          row.append(input, link, remove); list.append(row)
        } catch (error) { errors.push(`${file.name}: ${error.message}`) }
      }
      this.pending = false
      picker.disabled = false; picker.value = ''
      status.textContent = errors.join(' ') || "Файлы загружены. Сохраните карточку."
    })
  },
  destroyed() {
    this.disposed = true
    this.form.removeEventListener('submit', this.preventPending, true)
  }
}
