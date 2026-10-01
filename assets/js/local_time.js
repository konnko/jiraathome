export function formatLocalTime(value, timeZone) {
  return new Intl.DateTimeFormat("ru-RU", {
    day: "2-digit", month: "2-digit", year: "2-digit",
    hour: "2-digit", minute: "2-digit", ...(timeZone ? {timeZone} : {})
  }).format(new Date(value))
}

export const LocalTime = {
  mounted() { this.renderTime() },
  updated() { this.renderTime() },
  renderTime() {
    this.el.textContent = formatLocalTime(this.el.dateTime)
    this.el.title = Intl.DateTimeFormat().resolvedOptions().timeZone
  }
}
