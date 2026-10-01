defmodule Jiraathome.Repo.Migrations.AddAuthorsAndComments do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      add :author_name, :text
    end

    create table(:comments) do
      add :card_id, references(:cards, on_delete: :delete_all), null: false
      add :author_name, :text, null: false
      add :body, :text, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:comments, [:card_id])
  end
end
