defmodule Jiraathome.Files.Blob.Changes.DeleteStoredContents do
  @moduledoc "Removes the file from disk along with its record; an already missing file is not an error."
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, blob ->
      path = Jiraathome.Files.Storage.path(blob)

      case File.rm(path) do
        :ok -> {:ok, blob}
        {:error, :enoent} -> {:ok, blob}
        {:error, reason} -> raise File.Error, reason: reason, action: "delete", path: path
      end
    end)
  end

  @impl true
  def atomic(changeset, opts, context), do: {:ok, change(changeset, opts, context)}
end
