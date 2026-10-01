defmodule Jiraathome.Repo.Migrations.AddFileCleanup do
  use Ecto.Migration

  def up do
    alter table(:media) do
      add :orphaned_at, :utc_datetime_usec
    end

    create index(:media, [:orphaned_at])
    Oban.Migration.up()
  end

  def down do
    Oban.Migration.down()
    drop index(:media, [:orphaned_at])
    alter table(:media), do: remove(:orphaned_at)
  end
end
