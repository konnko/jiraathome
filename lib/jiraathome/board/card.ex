defmodule Jiraathome.Board.Card do
  use Ash.Resource,
    otp_app: :jiraathome,
    domain: Jiraathome.Board,
    data_layer: AshSqlite.DataLayer,
    notifiers: [Jiraathome.Board.Notifier]

  sqlite do
    table "cards"
    repo Jiraathome.Repo
    migration_defaults status: "\"backlog\"", description: "\"\""
  end

  actions do
    defaults [:read]

    read :list_newest_first do
      prepare build(sort: [id: :desc])
    end

    create :add do
      description "Добавляет карточку в колонку, где нажали «+», от имени вошедшего."
      accept [:title, :description, :attachment_ids]

      argument :status, :atom,
        allow_nil?: false,
        constraints: [one_of: [:backlog, :researching, :doing, :done]]

      argument :author_name, :string, allow_nil?: false
      change set_attribute(:status, arg(:status))
      change set_attribute(:author_name, arg(:author_name))
    end

    update :edit do
      description "Правка содержимого в редакторе. Колонка и автор здесь не меняются."
      accept [:title, :description, :attachment_ids]
    end

    update :move do
      argument :status, :atom,
        allow_nil?: false,
        constraints: [one_of: [:backlog, :researching, :doing, :done]]

      change set_attribute(:status, arg(:status))
    end

    destroy :destroy
  end

  attributes do
    integer_primary_key :id

    attribute :title, :string,
      allow_nil?: false,
      public?: true,
      constraints: [min_length: 1, trim?: true]

    attribute :author_name, :string, public?: true

    attribute :description, :string,
      default: "",
      allow_nil?: false,
      public?: true,
      constraints: [allow_empty?: true, trim?: false]

    attribute :status, :atom,
      default: :backlog,
      allow_nil?: false,
      public?: true,
      constraints: [one_of: [:backlog, :researching, :doing, :done]]

    # The editor always submits a blank hidden input so that removing every attachment works.
    attribute :attachment_ids, {:array, :string},
      default: [],
      allow_nil?: false,
      public?: true,
      constraints: [remove_nil_items?: true]

    create_timestamp :inserted_at, type: :utc_datetime
    update_timestamp :updated_at, type: :utc_datetime
  end

  relationships do
    has_many :comments, Jiraathome.Board.Comment, destination_attribute: :card_id
  end
end
