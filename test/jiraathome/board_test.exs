defmodule Jiraathome.BoardTest do
  use Jiraathome.DataCase
  alias Jiraathome.Board

  test "cards persist through create, edit, every column and delete" do
    Board.subscribe()

    assert {:ok, card} =
             Board.create_card("Анна", %{title: "  Первая задача  ", description: "Детали"})

    assert card.title == "Первая задача"
    assert card.status == :backlog
    assert_receive :board_updated
    assert Enum.map(Board.list_cards!(), & &1.id) == [card.id]

    for {status, _label} <- Board.columns() do
      assert {:ok, updated} = Board.move_card(Board.get_card!(card.id), status)
      assert updated.status == status
      assert Board.get_card!(card.id).status == status
    end

    assert {:ok, updated} = Board.update_card(card, %{title: "Новое название", description: ""})
    assert Board.get_card!(card.id).title == "Новое название"
    assert updated.description == ""
    assert :ok = Board.delete_card!(updated)
    assert [] = Board.list_cards!()
  end

  test "a title is required, including when editing" do
    assert {:error, changeset} = Board.create_card("Анна", %{title: "   "})
    assert Enum.any?(changeset.errors, &(&1.field == :title))
    assert {:ok, card} = Board.create_card("Анна", %{title: "Оставить"})
    assert {:error, changeset} = Board.update_card(card, %{title: ""})
    assert Enum.any?(changeset.errors, &(&1.field == :title))
    assert Board.get_card!(card.id).title == "Оставить"
  end

  test "only the four board statuses are accepted" do
    assert {:error, changeset} = Board.create_card("Анна", %{title: "Задача", status: "unknown"})
    assert Enum.any?(changeset.errors, &(&1.field == :status))
  end

  test "the creator is set separately from form data and cannot be changed by editing" do
    assert {:ok, card} = Board.create_card("Анна", %{title: "Задача", author_name: "Подмена"})
    assert card.author_name == "Анна"
    assert {:error, _} = Board.update_card(card, %{title: "Правка", author_name: "Борис"})
    assert Board.get_card!(card.id).author_name == "Анна"
  end

  test "comments keep their authors, are ordered and are deleted with the card" do
    {:ok, card} = Board.create_card("Анна", %{title: "Обсудить"})
    Board.subscribe()

    assert {:ok, first} =
             Board.create_comment(card.id, "Борис", %{body: "  Первый  ", author_name: "Подмена"})

    assert_receive :board_updated
    assert first.author_name == "Борис"
    assert first.body == "Первый"
    assert {:ok, second} = Board.create_comment(card.id, "Анна", %{body: "Ответ"})

    assert Enum.map(Board.list_comments!(card.id), &{&1.id, &1.body}) == [
             {first.id, "Первый"},
             {second.id, "Ответ"}
           ]

    Board.delete_card!(card)
    assert Board.list_comments!(card.id) == []
  end

  test "blank comments are not saved" do
    {:ok, card} = Board.create_card("Анна", %{title: "Задача"})
    assert {:error, changeset} = Board.create_comment(card.id, "Борис", %{body: "  "})
    assert Enum.any?(changeset.errors, &(&1.field == :body))
    assert Board.list_comments!(card.id) == []
  end
end
