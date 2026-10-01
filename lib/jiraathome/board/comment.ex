defmodule Jiraathome.Board.Comment do
  use Ash.Resource,
    otp_app: :jiraathome,
    domain: Jiraathome.Board,
    data_layer: AshSqlite.DataLayer,
    notifiers: [Jiraathome.Board.Notifier]

  sqlite do
    table "comments"
    repo Jiraathome.Repo

    custom_indexes do
      index [:card_id]
    end

    references do
      reference :card, on_delete: :delete
    end
  end

  actions do
    defaults [:read]

    read :for_card do
      argument :card_id, :integer, allow_nil?: false
      filter expr(card_id == ^arg(:card_id))
      prepare build(sort: [id: :asc])
    end

    create :create do
      accept [:body]
      argument :card_id, :integer, allow_nil?: false
      argument :author_name, :string, allow_nil?: false
      change set_attribute(:card_id, arg(:card_id))
      change set_attribute(:author_name, arg(:author_name))
    end
  end

  attributes do
    integer_primary_key :id

    attribute :body, :string,
      allow_nil?: false,
      public?: true,
      constraints: [min_length: 1, trim?: true]

    attribute :author_name, :string, allow_nil?: false, public?: true
    create_timestamp :inserted_at, type: :utc_datetime
  end

  relationships do
    belongs_to :card, Jiraathome.Board.Card, attribute_type: :integer, allow_nil?: false
  end
end
