defmodule JiraathomeWeb.BoardLive do
  @moduledoc false
  use JiraathomeWeb, :live_view
  alias Jiraathome.Board
  alias Jiraathome.Board.Card
  alias JiraathomeWeb.Time

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Board.subscribe()

    {:ok,
     assign(socket,
       cards: Board.list_cards!(),
       columns: Board.columns(),
       editing: nil,
       form: nil,
       comments: [],
       comment_form: nil,
       page_title: "Доска задач"
     )}
  end

  @impl true
  def handle_event("new", %{"status" => status}, socket) do
    form =
      Board.form_to_add_card(status, socket.assigns.current_name,
        as: "card",
        post_process_errors: &form_error/3
      )

    {:noreply, assign(socket, editing: %Card{status: status}, form: to_form(form))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    card = Board.get_card!(id)
    form = Board.form_to_edit_card(card, as: "card", post_process_errors: &form_error/3)

    {:noreply,
     assign(socket,
       editing: card,
       form: to_form(form),
       comments: Board.list_comments!(card.id),
       comment_form: comment_form(card, socket.assigns.current_name)
     )}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, editing: nil, form: nil)}
  end

  def handle_event("save", %{"card" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, _card} ->
        {:noreply, assign(socket, editing: nil, form: nil, cards: Board.list_cards!())}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  def handle_event("move", %{"card_id" => id, "status" => status, "index" => index}, socket) do
    Board.move_card!(Board.get_card!(id), status, index)
    {:noreply, assign(socket, cards: Board.list_cards!())}
  end

  def handle_event("delete", _params, socket) do
    Board.delete_card!(Board.get_card!(socket.assigns.editing.id))
    {:noreply, assign(socket, editing: nil, form: nil, cards: Board.list_cards!())}
  end

  def handle_event("validate_comment", %{"comment" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.comment_form.source, params)
    {:noreply, assign(socket, comment_form: to_form(form))}
  end

  def handle_event("add_comment", %{"comment" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.comment_form.source, params: params) do
      {:ok, comment} ->
        {:noreply,
         assign(socket,
           comments: Board.list_comments!(comment.card_id),
           comment_form: comment_form(socket.assigns.editing, socket.assigns.current_name)
         )}

      {:error, form} ->
        {:noreply, assign(socket, comment_form: to_form(form))}
    end
  end

  @impl true
  def handle_info(:board_updated, socket) do
    comments =
      case socket.assigns.editing do
        %Card{id: id} when not is_nil(id) -> Board.list_comments!(id)
        _ -> []
      end

    {:noreply, assign(socket, cards: Board.list_cards!(), comments: comments)}
  end

  defp comment_form(card, author_name) do
    card.id
    |> Board.form_to_add_comment(author_name, as: "comment", post_process_errors: &form_error/3)
    |> to_form()
  end

  defp form_error(_form, _path, {field, message, vars}) do
    translated =
      if message in [
           "is required",
           "must be present",
           "length must be greater than or equal to %{min}"
         ], do: "Заполните поле", else: message

    {field, translated, vars}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.workspace flash={@flash} current_name={@current_name} page={:board}>
      <div id="connection-status" class="connection-status" role="status">
        Связь прервалась. Подключаемся заново…
      </div>
      <div id="board" phx-hook="Board" class="board-grid">
        <section
          :for={{status, label} <- @columns}
          id={"column-#{status}"}
          data-status={status}
          class="board-column"
          aria-labelledby={"heading-#{status}"}
        >
          <header class="column-header">
            <div class="column-title">
              <span class={"status-dot status-#{status}"} aria-hidden="true"></span>
              <h2 id={"heading-#{status}"}>{label}</h2>
              <span class="column-count">{Enum.count(@cards, &(&1.status == status))}</span>
            </div>
            <button
              class="add-card"
              phx-click={JS.push_focus() |> JS.push("new")}
              phx-value-status={status}
              aria-label={"Добавить карточку: #{label}"}
            >＋</button>
          </header>
          <div class="column-cards">
            <article
              :for={card <- Enum.filter(@cards, &(&1.status == status))}
              id={"card-#{card.id}"}
              data-card-id={card.id}
              draggable="true"
              class="task-card card"
            >
              <button
                class="card-content"
                phx-click={JS.push_focus() |> JS.push("edit")}
                phx-value-id={card.id}
              >
                <h3>{card.title}</h3>
              </button>
              <div :if={card.description not in [nil, ""]} class="card-description markdown-content">
                {Phoenix.HTML.raw(JiraathomeWeb.Markdown.html(card.description))}
              </div>
              <div :if={card.attachment_ids != []} class="card-attachments px-2 pb-2">
                <a
                  :for={file <- Jiraathome.Files.list_attachments!(card.attachment_ids)}
                  href={Jiraathome.Files.Storage.url(file)}
                  data-image-preview={if String.starts_with?(file.content_type, "image/"), do: "true"}
                  target="_blank"
                  rel="noopener"
                  class="block text-xs underline"
                >{file.name}</a>
              </div>
              <footer class="card-meta">
                <Time.local id={"card-time-#{card.id}"} timestamp={card.updated_at} />
                <span class="card-author">{card.author_name || "не указан"}</span>
              </footer>
            </article>
            <p :if={Enum.all?(@cards, &(&1.status != status))} class="empty-column">Пока пусто</p>
          </div>
        </section>
      </div>
      <div
        :if={@form}
        id="card-editor"
        class="editor-backdrop"
        role="dialog"
        aria-modal="true"
        aria-labelledby="editor-title"
        phx-window-keydown="cancel"
        phx-key="Escape"
        phx-remove={JS.pop_focus()}
      >
        <.focus_wrap
          id="editor-focus"
          class="editor-panel card bg-base-100"
          phx-mounted={JS.focus_first()}
        >
          <header class="editor-header">
            <h2 id="editor-title">
              <%= if @editing.id do %>
                <span class="editor-author">{@editing.author_name || "не указан"}</span>
                <span aria-hidden="true"> · </span>
                <Time.local id="editing-updated-at" timestamp={@editing.updated_at} />
              <% else %>
                Новая карточка
              <% end %>
            </h2>
            <button
              type="button"
              class="btn btn-ghost btn-sm"
              phx-click="cancel"
              aria-label="Закрыть"
            >✕</button>
          </header>
          <.form for={@form} id="card-form" phx-submit="save" class="editor-form">
            <.input
              field={@form[:title]}
              label="Заголовок"
              placeholder="Что нужно сделать?"
              required
            />
            <div class="form-field">
              <label for="card_description" class="field-label">Описание</label>
              <div
                id="card-description-editor"
                phx-hook="CardDescription"
                phx-update="ignore"
                class="card-description-editor"
              >
                <textarea
                  id="card_description"
                  name={@form[:description].name}
                  class="textarea w-full"
                  rows="6"
                >{Phoenix.HTML.Form.normalize_value("textarea", @form[:description].value)}</textarea>
                <div class="card-milkdown"></div>
              </div>
            </div>
            <div id="card-attachments" phx-hook="Attachments" phx-update="ignore" class="form-field">
              <label class="field-label" for="attachment-picker">Вложения</label>
              <input type="hidden" name="card[attachment_ids][]" value="" />
              <div class="attachment-list">
                <div
                  :for={file <- Jiraathome.Files.list_attachments!(@editing.attachment_ids)}
                  class="attachment-row"
                >
                  <input type="hidden" name="card[attachment_ids][]" value={file.id} />
                  <a
                    href={Jiraathome.Files.Storage.url(file)}
                    data-image-preview={
                      if String.starts_with?(file.content_type, "image/"), do: "true"
                    }
                    target="_blank"
                    rel="noopener"
                  >{file.name}</a>
                  <button type="button" data-remove-attachment aria-label={"Убрать #{file.name}"}>✕</button>
                </div>
              </div>
              <input id="attachment-picker" type="file" multiple class="file-input bg-white" />
              <p class="text-muted">До 20 МБ на файл</p>
              <p class="attachment-status text-muted" role="status"></p>
            </div>
            <div class="editor-actions">
              <button
                :if={@editing.id}
                type="button"
                id="delete-card"
                class="btn btn-ghost text-error"
                phx-click="delete"
                data-confirm="Удалить карточку?"
              >Удалить</button>
              <div class="save-actions">
                <button type="button" class="btn btn-ghost" phx-click="cancel">Отмена</button>
                <button type="submit" class="btn btn-primary" phx-disable-with="Сохраняем…">Сохранить</button>
              </div>
            </div>
          </.form>
          <section
            :if={@editing.id}
            id="comments"
            class="comments-section"
            aria-labelledby="comments-title"
          >
            <h3 id="comments-title">
              Комментарии <span class="column-count">{length(@comments)}</span>
            </h3>
            <p :if={@comments == []} class="text-muted">Пока нет комментариев.</p>
            <ol class="comments-list">
              <li :for={comment <- @comments} id={"comment-#{comment.id}"} class="comment">
                <div class="comment-heading">
                  <strong>{comment.author_name}</strong>
                  <Time.local id={"comment-time-#{comment.id}"} timestamp={comment.inserted_at} />
                </div>
                <p class="comment-body">{comment.body}</p>
              </li>
            </ol>
            <.form
              for={@comment_form}
              id="comment-form"
              phx-change="validate_comment"
              phx-submit="add_comment"
              class="editor-form"
            >
              <.input
                field={@comment_form[:body]}
                type="textarea"
                label="Комментарий"
                rows="3"
                placeholder="Напишите комментарий…"
                required
              />
              <button
                type="submit"
                class="btn btn-primary self-end"
                phx-disable-with="Добавляем…"
              >
                Добавить комментарий
              </button>
            </.form>
          </section>
        </.focus_wrap>
      </div>
    </Layouts.workspace>
    """
  end
end
