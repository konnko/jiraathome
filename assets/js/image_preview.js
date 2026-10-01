export const ImagePreview = {
  mounted() {
    this.dialog = document.createElement('dialog')
    this.dialog.className = 'image-preview'
    this.dialog.setAttribute('aria-label', 'Просмотр изображения')
    const close = document.createElement('button')
    close.type = 'button'
    close.className = 'image-preview-close'
    close.setAttribute('aria-label', 'Закрыть изображение')
    close.textContent = '✕'
    this.image = document.createElement('img')
    this.dialog.append(close, this.image)
    document.body.append(this.dialog)
    this.dialog.addEventListener('click', () => this.dialog.close())
    this.dialog.addEventListener('keydown', event => {
      if (event.key === 'Escape') event.stopPropagation()
    })
    this.dialog.addEventListener('close', () => {
      this.image.removeAttribute('src')
      if (this.opener?.isConnected) this.opener.focus({preventScroll: true})
    })
    this.open = event => {
      const link = event.target.closest('a[data-image-preview="true"]')
      if (!link || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
      event.preventDefault()
      event.stopPropagation()
      this.opener = link
      this.image.src = link.href
      this.image.alt = link.textContent.trim()
      this.dialog.showModal()
    }
    this.el.addEventListener('click', this.open)
  },
  destroyed() {
    this.el.removeEventListener('click', this.open)
    this.dialog.close()
    this.dialog.remove()
  }
}
