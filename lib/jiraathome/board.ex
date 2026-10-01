defmodule Jiraathome.Board do
  import Ecto.Query
  alias Jiraathome.Board.Card
  alias Jiraathome.Board.Comment
  alias Jiraathome.Repo

  def columns do
    [backlog: "Бэклог", researching: "Исследуется", doing: "Делается", done: "Готово"]
  end

  def subscribe, do: Phoenix.PubSub.subscribe(Jiraathome.PubSub, "board")
  def list_cards, do: Repo.all(from card in Card, order_by: [desc: card.id])
  def get_card!(id), do: Repo.get!(Card, id)
  def change_card(card, attrs \\ %{}), do: Card.changeset(card, attrs)

  def create_card(attrs, author_name) do
    %Card{author_name: author_name}
    |> Card.changeset(attrs)
    |> Ecto.Changeset.validate_required([:author_name], message: "Заполните поле")
    |> Repo.insert()
    |> broadcast()
  end

  def update_card(card, attrs) do
    card |> Card.changeset(attrs) |> Repo.update() |> broadcast()
  end

  def delete_card(card) do
    card |> Repo.delete!()
    Phoenix.PubSub.broadcast(Jiraathome.PubSub, "board", :board_updated)
    :ok
  end

  def list_comments(card) do
    Repo.all(from comment in Comment, where: comment.card_id == ^card.id, order_by: comment.id)
  end

  def change_comment(comment, attrs \\ %{}), do: Comment.changeset(comment, attrs)

  def create_comment(card, attrs, author_name) do
    %Comment{card_id: card.id, author_name: author_name}
    |> Comment.changeset(attrs)
    |> Repo.insert()
    |> broadcast()
  end

  defp broadcast({:ok, _card} = result) do
    Phoenix.PubSub.broadcast(Jiraathome.PubSub, "board", :board_updated)
    result
  end

  defp broadcast({:error, _changeset} = result), do: result
end
