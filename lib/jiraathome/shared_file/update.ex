defmodule Jiraathome.SharedFile.Update do
  use Ash.Resource,
    otp_app: :jiraathome,
    domain: Jiraathome.Documents,
    data_layer: AshSqlite.DataLayer

  sqlite do
    table "shared_file_updates"
    repo Jiraathome.Repo
  end

  actions do
    defaults [:read]

    read :after_sequence do
      argument :sequence, :integer, allow_nil?: false
      filter expr(id > ^arg(:sequence))
      prepare build(sort: [id: :asc])
    end

    create :append do
      accept [:token, :data, :author_name]
    end
  end

  attributes do
    integer_primary_key :id
    attribute :token, :string, allow_nil?: false, public?: true
    attribute :data, :binary, allow_nil?: false, public?: true
    attribute :author_name, :string, allow_nil?: false, public?: true
    create_timestamp :inserted_at, type: :utc_datetime
  end

  identities do
    identity :token, [:token]
  end
end
