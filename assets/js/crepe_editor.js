import {Crepe} from "@milkdown/crepe"
import {scopeEditorIcons} from "./editor_icons"

import {uploadMedia} from "./media_upload"
import {uploadConfig} from "@milkdown/kit/plugin/upload"

const report = text => {
  const status = document.querySelector("#media-upload-status")
  if (status) status.textContent = text
}
const uploadImage = async file => {
  report("Загружаем изображение…")
  try {
    const media = await uploadMedia(file)
    if (!media.type.startsWith("image/")) throw new Error("Поддерживаются PNG, JPEG, GIF и WebP")
    report("")
    return media.url
  } catch (error) { report(error.message); throw error }
}

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
  crepe.editor.config(ctx => {
    ctx.update(uploadConfig.key, config => ({
      ...config,
      uploader: async (files, schema) => {
        report("Загружаем файлы…")
        const nodes = []
        const errors = []
        for (const file of Array.from(files)) {
          try {
            const media = await uploadMedia(file)
            if (media.type.startsWith("image/")) {
              nodes.push(schema.nodes.image.create({src: media.url, alt: media.name}))
            } else {
              nodes.push(schema.nodes.paragraph.create(null, schema.text(media.name, [schema.marks.link.create({href: media.url})])))
            }
          } catch (error) { errors.push(error.message) }
        }
        report(errors.join(" "))
        return nodes
      }
    }))
  })
  const stopScoping = scopeEditorIcons(root)
  crepe.on(listener => listener.destroy(stopScoping))
  return crepe
}
