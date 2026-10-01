defmodule JiraathomeWeb.BoardLive do
  use JiraathomeWeb, :live_view
  alias Jiraathome.Board
  alias Jiraathome.Board.Card
  alias Jiraathome.Board.Comment
  alias JiraathomeWeb.Time

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Board.subscribe()

    {:ok,
     assign(socket,
       cards: Board.list_cards(),
       columns: Board.columns(),
       editing: nil,
       form: nil,
       comments: [],
       comment_form: nil,
       page_title: "Доска задач"
     )}
  end

  @impl true
  def handle_event("new", params, socket) do
    card = %Card{}
    changeset = Board.change_card(card, %{status: params["status"] || "backlog"})
    {:noreply, assign(socket, editing: card, form: to_form(changeset))}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    card = Board.get_card!(id)

    {:noreply,
     assign(socket,
       editing: card,
       form: to_form(Board.change_card(card)),
       comments: Board.list_comments(card),
       comment_form: comment_form(card, socket.assigns.current_name)
     )}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, editing: nil, form: nil)}
  end

  def handle_event("save", %{"card" => attrs}, socket) do
    result =
      case socket.assigns.editing do
        %Card{id: nil} -> Board.create_card(attrs, socket.assigns.current_name)
        card -> Board.update_card(Board.get_card!(card.id), attrs)
      end

    case result do
      {:ok, _card} ->
        {:noreply, assign(socket, editing: nil, form: nil, cards: Board.list_cards())}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("move", %{"card_id" => id, "status" => status}, socket) do
    {:ok, _card} = Board.update_card(Board.get_card!(id), %{status: status})
    {:noreply, assign(socket, cards: Board.list_cards())}
  end

  def handle_event("delete", _params, socket) do
    Board.delete_card(Board.get_card!(socket.assigns.editing.id))
    {:noreply, assign(socket, editing: nil, form: nil, cards: Board.list_cards())}
  end

  def handle_event("validate_comment", %{"comment" => attrs}, socket) do
    changeset =
      %Comment{card_id: socket.assigns.editing.id, author_name: socket.assigns.current_name}
      |> Board.change_comment(attrs)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, comment_form: to_form(changeset))}
  end

  def handle_event("add_comment", %{"comment" => attrs}, socket) do
    card = socket.assigns.editing

    case Board.create_comment(card, attrs, socket.assigns.current_name) do
      {:ok, _comment} ->
        {:noreply,
         assign(socket,
           comments: Board.list_comments(card),
           comment_form: comment_form(card, socket.assigns.current_name)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, comment_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_info(:board_updated, socket) do
    comments =
      case socket.assigns.editing do
        %Card{id: id} = card when not is_nil(id) -> Board.list_comments(card)
        _ -> []
      end

    {:noreply, assign(socket, cards: Board.list_cards(), comments: comments)}
  end

  defp comment_form(card, name) do
    %Comment{card_id: card.id, author_name: name}
    |> Board.change_comment()
    |> to_form()
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
                <span class="card-number">#{String.pad_leading(to_string(card.id), 3, "0")}</span>
                <h3>{card.title}</h3>
                <p class="card-author">Автор: {card.author_name || "не указан"}</p>
                <p class="card-time">
                  Создана
                  <time datetime={DateTime.to_iso8601(card.inserted_at)}>{Time.moscow(
                    card.inserted_at
                  )}</time>
                </p>
                <p :if={card.updated_at != card.inserted_at} class="card-time">
                  Изменена
                  <time datetime={DateTime.to_iso8601(card.updated_at)}>{Time.moscow(card.updated_at)}</time>
                </p>
              </button>
              <div :if={card.description not in [nil, ""]} class="card-description markdown-content">
                {Phoenix.HTML.raw(JiraathomeWeb.Markdown.html(card.description))}
              </div>
              <form id={"move-card-#{card.id}"} phx-change="move" class="card-status-form">
                <input type="hidden" name="card_id" value={card.id} />
                <select
                  name="status"
                  class="card-status"
                  aria-label={"Столбец карточки #{card.title}"}
                >
                  {Phoenix.HTML.Form.options_for_select(
                    Enum.map(@columns, fn {value, text} -> {text, value} end),
                    card.status
                  )}
                </select>
              </form>
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
              {if @editing.id, do: "Изменить карточку", else: "Новая карточка"}
            </h2>
            <button
              type="button"
              class="btn btn-ghost btn-sm"
              phx-click="cancel"
              aria-label="Закрыть"
            >✕</button>
          </header>
          <p :if={@editing.id} class="editor-author">
            Автор: {@editing.author_name || "не указан"}
          </p>
          <p :if={@editing.id} class="editor-timestamps text-muted">
            Создана
            <time datetime={DateTime.to_iso8601(@editing.inserted_at)}>{Time.moscow(
              @editing.inserted_at
            )}</time><br /> Изменена
            <time datetime={DateTime.to_iso8601(@editing.updated_at)}>{Time.moscow(
              @editing.updated_at
            )}</time>
          </p>
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
            <.input
              field={@form[:status]}
              type="select"
              label="Столбец"
              options={Enum.map(@columns, fn {value, label} -> {label, value} end)}
            />
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
                  <time datetime={DateTime.to_iso8601(comment.inserted_at)}>
                    {Time.moscow(comment.inserted_at)}
                  </time>
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
