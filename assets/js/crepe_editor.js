import {Crepe} from "@milkdown/crepe"
import {scopeEditorIcons} from "./editor_icons"

// Store uploaded images in the shared document, rather than tab-local blob URLs.
const uploadImage = file => new Promise((resolve, reject) => {
  const reader = new FileReader()
  reader.onload = () => resolve(reader.result)
  reader.onerror = () => reject(reader.error)
  reader.readAsDataURL(file)
})

export function createCrepe(root, {placeholder = "Начните писать или введите / для выбора блока", features = {}} = {}) {
  const crepe = new Crepe({
    root,
    features,
    featureConfigs: {
      [Crepe.Feature.Placeholder]: {text: placeholder},
      [Crepe.Feature.LinkTooltip]: {inputPlaceholder: "Вставьте ссылку…"},
      [Crepe.Feature.ImageBlock]: {
        onUpload: uploadImage,
        inlineUploadButton: "Загрузить",
        inlineUploadPlaceholderText: "или вставьте ссылку",
        blockUploadButton: "Загрузить изображение",
        blockConfirmButton: "Добавить",
        blockCaptionPlaceholderText: "Подпись к изображению",
        blockUploadPlaceholderText: "или вставьте ссылку"
      },
      [Crepe.Feature.CodeMirror]: {
        searchPlaceholder: "Язык кода",
        copyText: "Копировать",
        noResultText: "Ничего не найдено"
      },
      [Crepe.Feature.BlockEdit]: {
        textGroup: {
          label: "Текст", text: {label: "Обычный текст"},
          h1: {label: "Заголовок 1"}, h2: {label: "Заголовок 2"},
          h3: {label: "Заголовок 3"}, h4: {label: "Заголовок 4"},
          h5: {label: "Заголовок 5"}, h6: {label: "Заголовок 6"},
          quote: {label: "Цитата"}, divider: {label: "Разделитель"}
        },
        listGroup: {
          label: "Списки", bulletList: {label: "Маркированный список"},
          orderedList: {label: "Нумерованный список"}, taskList: {label: "Чек-лист"}
        },
        advancedGroup: {
          label: "Блоки", image: {label: "Изображение"}, codeBlock: {label: "Код"},
          table: {label: "Таблица"}, math: {label: "Формула"}
        }
      }
    }
  })
  const stopScoping = scopeEditorIcons(root)
  crepe.on(listener => listener.destroy(stopScoping))
  return crepe
}
