defmodule Jiraathome.SharedFile do
  @moduledoc "A single ordered, persistent stream of updates for the shared document."
  use GenServer
  import Ecto.Query
  alias Jiraathome.Repo
  alias Jiraathome.SharedFile.Update

  @topic "shared_file:updates"

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def subscribe, do: Phoenix.PubSub.subscribe(Jiraathome.PubSub, @topic)
  def updates_after(sequence), do: GenServer.call(__MODULE__, {:updates_after, sequence})

  def save(token, encoded, name) when is_binary(token) and is_binary(encoded) do
    case Base.decode64(encoded) do
      {:ok, data} when byte_size(data) > 0 ->
        GenServer.call(__MODULE__, {:save, token, data, name})

      _ ->
        {:error, :invalid_update}
    end
  end

  @impl true
  def init(_opts), do: {:ok, nil}

  @impl true
  def handle_call({:updates_after, sequence}, _from, state) do
    updates = Repo.all(from u in Update, where: u.id > ^sequence, order_by: u.id)
    {:reply, Enum.map(updates, &payload/1), state}
  end

  def handle_call({:save, token, data, name}, _from, state) do
    # A reconnect can resend an unacknowledged batch. Persist it only once.
    case Repo.get_by(Update, token: token) do
      nil ->
        update = Repo.insert!(%Update{token: token, data: data, author_name: name})
        payload = payload(update)
        Phoenix.PubSub.broadcast(Jiraathome.PubSub, @topic, {:file_updated, payload})
        {:reply, {:ok, payload}, state}

      update ->
        {:reply, {:ok, payload(update)}, state}
    end
  end

  defp payload(update) do
    %{
      sequence: update.id,
      data: Base.encode64(update.data),
      author: update.author_name,
      saved_at: DateTime.to_iso8601(update.inserted_at)
    }
  end
end
