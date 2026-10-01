defmodule Jiraathome.Repo.Migrations.CreateSharedFileUpdates do
  use Ecto.Migration

  def change do
    create table(:shared_file_updates) do
      add :token, :string, null: false
      add :data, :binary, null: false
      add :author_name, :string, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:shared_file_updates, [:token])
  end
end
