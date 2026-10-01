defmodule JiraathomeWeb.FileLive do
  use JiraathomeWeb, :live_view
  alias Jiraathome.SharedFile
  alias JiraathomeWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      SharedFile.subscribe()
      Presence.join(socket.assigns.current_name)
    end

    {:ok, assign(socket, page_title: "Общий файл", viewers: Presence.names())}
  end

  @impl true
  def handle_event("file_sync", %{"after" => sequence}, socket)
      when is_integer(sequence) and sequence >= 0 do
    {:reply, %{updates: SharedFile.updates_after(sequence)}, socket}
  end

  def handle_event("file_save", %{"token" => token, "data" => data}, socket) do
    case SharedFile.save(token, data, socket.assigns.current_name) do
      {:ok, update} -> {:reply, %{ok: true, update: update}, socket}
      {:error, _reason} -> {:reply, %{ok: false}, socket}
    end
  end

  @impl true
  def handle_info({:file_updated, update}, socket) do
    {:noreply, push_event(socket, "file_update", update)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, viewers: Presence.names())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.workspace flash={@flash} current_name={@current_name} page={:file}>
      <section
        id="shared-file"
        phx-hook="SharedFile"
        class="shared-file"
        aria-label="Общий документ"
      >
        <div id="milkdown-editor" class="file-editor crepe" phx-update="ignore"></div>
        <p id="media-upload-status" role="status" phx-update="ignore" class="text-muted"></p>
        <footer class="file-statusbar">
          <span id="file-status" class="text-muted" role="status" phx-update="ignore">Загрузка…</span>
          <div
            id="file-presence"
            class="file-presence"
            aria-label="Сейчас на странице"
            aria-live="polite"
          >
            <span :for={name <- @viewers} class="viewer-badge"><span class="presence-dot"></span>{name}</span>
          </div>
          <span id="file-saved-at" class="text-muted" phx-update="ignore"></span>
        </footer>
      </section>
    </Layouts.workspace>
    """
  end
end
