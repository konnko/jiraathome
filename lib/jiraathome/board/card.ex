defmodule Jiraathome.Board.Card do
  use Ash.Resource,
    otp_app: :jiraathome,
    domain: Jiraathome.Board,
    data_layer: AshSqlite.DataLayer,
    notifiers: [Jiraathome.Board.Notifier]

  sqlite do
    table "cards"
    repo Jiraathome.Repo
    migration_defaults status: "\"backlog\"", description: "\"\"", position: "0.0"
  end

  actions do
    defaults [:read]

    read :list_in_board_order do
      prepare build(sort: [position: :asc, id: :desc])
    end

    read :list_column do
      argument :status, :atom, allow_nil?: false
      filter expr(status == ^arg(:status))
      prepare build(sort: [position: :asc, id: :desc])
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
      argument :index, :integer, default: 0, allow_nil?: false
      change Jiraathome.Board.Changes.PlaceInColumn
    end

    update :edit do
      description "Правка содержимого в редакторе. Колонка и автор здесь не меняются."
      accept [:title, :description, :attachment_ids]
    end

    update :move do
      description "Переносит карточку в колонку на место index среди остальных её карточек."
      require_atomic? false

      argument :status, :atom,
        allow_nil?: false,
        constraints: [one_of: [:backlog, :researching, :doing, :done]]

      argument :index, :integer, allow_nil?: false, constraints: [min: 0]
      change set_attribute(:status, arg(:status))
      change Jiraathome.Board.Changes.PlaceInColumn
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

    # Order inside a column. Floats let a move land between two neighbours without renumbering.
    attribute :position, :float, default: 0.0, allow_nil?: false, public?: true

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
