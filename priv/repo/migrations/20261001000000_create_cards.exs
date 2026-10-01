defmodule Jiraathome.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :title, :text, null: false
      add :description, :text, null: false, default: ""
      add :status, :text, null: false, default: "backlog"
      timestamps(type: :utc_datetime)
    end
  end
end
