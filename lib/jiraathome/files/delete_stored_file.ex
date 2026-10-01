defmodule Jiraathome.Files.DeleteStoredFile do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      path = Jiraathome.Files.Storage.path(changeset.data)

      case File.rm(path) do
        :ok -> changeset
        {:error, :enoent} -> changeset
        {:error, reason} -> raise File.Error, reason: reason, action: "delete", path: path
      end
    end)
  end
end
