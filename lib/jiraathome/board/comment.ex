defmodule Jiraathome.Board.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string
    field :author_name, :string
    belongs_to :card, Jiraathome.Board.Card
    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body])
    |> update_change(:body, fn body ->
      if is_binary(body), do: String.trim(body), else: body
    end)
    |> validate_required([:body, :author_name, :card_id], message: "Заполните поле")
  end
end
