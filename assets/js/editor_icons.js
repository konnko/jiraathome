let nextIcon = 0

// Crepe repeats inline SVGs with fixed IDs; scope their references to each copy.
export function scopeEditorIcons(root) {
  const seen = new WeakSet()
  const scope = () => {
    for (const svg of root.querySelectorAll("svg")) {
      if (seen.has(svg)) continue
      seen.add(svg)
      const prefix = `editor-icon-${++nextIcon}-`
      for (const definition of svg.querySelectorAll("[id]")) {
        const oldId = definition.id
        const newId = prefix + oldId
        definition.id = newId
        for (const node of [svg, ...svg.querySelectorAll("*")]) {
          for (const attribute of Array.from(node.attributes)) {
            const value = attribute.value.replaceAll(`url(#${oldId})`, `url(#${newId})`)
            if (value !== attribute.value) node.setAttribute(attribute.name, value)
            if (["href", "xlink:href"].includes(attribute.name) && value === `#${oldId}`) {
              node.setAttribute(attribute.name, `#${newId}`)
            }
          }
        }
      }
    }
  }
  const observer = new MutationObserver(scope)
  observer.observe(root, {childList: true, subtree: true})
  return () => observer.disconnect()
}
