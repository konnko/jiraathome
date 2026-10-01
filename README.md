# jiraathome

Простенький self-hosted канбан с обновлениями в реальном времени и общим документом.
Phoenix LiveView, Milkdown и SQLite; вход по имени и общему паролю.

## Как захостить

Запусти образ через Docker Compose или панель деплоя. В примере ниже замени
`registry.example.com/your-name/jiraathome:latest` адресом своего образа.
Для приватного реестра сначала выполни `docker login <адрес-реестра>`.

```yaml
services:
  app:
    image: registry.example.com/your-name/jiraathome:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:4000:4000"
    environment:
      APP_PASSWORD: ${APP_PASSWORD:?Set APP_PASSWORD}
      SECRET_KEY_BASE: ${SECRET_KEY_BASE:?Set SECRET_KEY_BASE}
      PHX_HOST: jira.example.com
      PHX_SCHEME: https
    volumes:
      - data:/data
volumes:
  data:
    name: jiraathome_data
```

1. Рядом с `compose.yaml` создай `.env`: задай `APP_PASSWORD` и `SECRET_KEY_BASE`
   (ключ сгенерируй командой `openssl rand -base64 48`). Сохраняй ключ между редеплоями.
2. Замени `jira.example.com` своим доменом без `https://`. Настрой HTTPS-прокси
   на порт 4000 с поддержкой WebSocket. В панели деплоя укажи те же переменные и порт.
3. Подключи постоянный volume к `/data`. При обновлениях используй тот же volume;
   если база уже существует — подключи существующий. Не выполняй `docker compose down -v`.
4. Запусти или обнови: `docker compose pull && docker compose up -d`.

Миграции выполняются автоматически. Для локального HTTP укажи `PHX_HOST=localhost`
и `PHX_SCHEME=http`, затем открой http://localhost:4000.

Вход ограничен тремя попытками в час с одного IP. Без настройки доверенного прокси
посетители за reverse proxy делят общий лимит; перезапуск приложения сбрасывает счётчик.

Файлы и изображения (до 20 МБ каждый) хранятся в `/data/uploads` в том же volume.
Разреши в HTTPS-прокси запросы размером не менее 21 МБ. Скачивание доступно после входа.

Каждое воскресенье в 03:00 UTC сервер очищает неиспользуемые файлы после недельного
периода ожидания. Вложения карточек и файлы из текущего общего документа сохраняются.
