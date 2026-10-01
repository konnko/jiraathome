defmodule Jiraathome.Repo.Migrations.AddMedia do
  use Ecto.Migration

  def change do
    create table(:media, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :text, null: false
      add :content_type, :string, null: false
      add :size, :integer, null: false
      timestamps(updated_at: false)
    end

    alter table(:cards) do
      add :attachment_ids, {:array, :string}, default: [], null: false
    end
  end
end
