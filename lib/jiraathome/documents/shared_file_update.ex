defmodule Jiraathome.Documents.SharedFileUpdate do
  @moduledoc "One persisted Yjs update of the shared document, in arrival order."
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

    read :list_after_sequence do
      argument :sequence, :integer, allow_nil?: false
      filter expr(id > ^arg(:sequence))
      prepare build(sort: [id: :asc])
    end

    create :append do
      description "The token lets a reconnecting client resend a batch without duplicating it."
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
