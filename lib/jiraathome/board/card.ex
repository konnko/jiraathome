defmodule Jiraathome.Board.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :title, :string
    field :author_name, :string
    field :description, :string, default: ""
    field :status, Ecto.Enum, values: [:backlog, :researching, :doing, :done], default: :backlog
    timestamps(type: :utc_datetime)
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [:title, :description, :status])
    |> update_change(:title, fn title ->
      if is_binary(title), do: String.trim(title), else: title
    end)
    |> validate_required([:title, :status], message: "Заполните поле")
  end
end
