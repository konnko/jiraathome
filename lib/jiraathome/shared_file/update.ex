defmodule Jiraathome.SharedFile.Update do
  use Ecto.Schema

  schema "shared_file_updates" do
    field :token, :string
    field :data, :binary
    field :author_name, :string
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
