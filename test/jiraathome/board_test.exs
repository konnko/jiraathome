defmodule Jiraathome.BoardTest do
  use Jiraathome.DataCase
  alias Jiraathome.Board

  test "cards persist through create, edit, every column and delete" do
    Board.subscribe()

    assert {:ok, card} =
             Board.create_card(%{title: "  Первая задача  ", description: "Детали"}, "Анна")

    assert card.title == "Первая задача"
    assert card.status == :backlog
    assert_receive :board_updated
    assert [^card] = Board.list_cards()

    for {status, _label} <- Board.columns() do
      assert {:ok, updated} = Board.update_card(Board.get_card!(card.id), %{status: status})
      assert updated.status == status
      assert Board.get_card!(card.id).status == status
    end

    assert {:ok, updated} = Board.update_card(card, %{title: "Новое название", description: ""})
    assert Board.get_card!(card.id).title == "Новое название"
    assert updated.description == ""
    assert :ok = Board.delete_card(updated)
    assert [] = Board.list_cards()
  end

  test "a title is required, including when editing" do
    assert {:error, changeset} = Board.create_card(%{title: "   "}, "Анна")
    assert "Заполните поле" in errors_on(changeset).title
    assert {:ok, card} = Board.create_card(%{title: "Оставить"}, "Анна")
    assert {:error, changeset} = Board.update_card(card, %{title: ""})
    assert "Заполните поле" in errors_on(changeset).title
    assert Board.get_card!(card.id).title == "Оставить"
  end

  test "only the four board statuses are accepted" do
    assert {:error, changeset} = Board.create_card(%{title: "Задача", status: "unknown"}, "Анна")
    assert errors_on(changeset).status != []
  end

  test "the creator is set separately from form data and cannot be changed by editing" do
    assert {:ok, card} = Board.create_card(%{title: "Задача", author_name: "Подмена"}, "Анна")
    assert card.author_name == "Анна"
    assert {:ok, updated} = Board.update_card(card, %{title: "Правка", author_name: "Борис"})
    assert updated.author_name == "Анна"
  end

  test "comments keep their authors, are ordered and are deleted with the card" do
    {:ok, card} = Board.create_card(%{title: "Обсудить"}, "Анна")
    Board.subscribe()

    assert {:ok, first} =
             Board.create_comment(card, %{body: "  Первый  ", author_name: "Подмена"}, "Борис")

    assert_receive :board_updated
    assert first.author_name == "Борис"
    assert first.body == "Первый"
    assert {:ok, second} = Board.create_comment(card, %{body: "Ответ"}, "Анна")
    assert Board.list_comments(card) == [first, second]
    Board.delete_card(card)
    assert Board.list_comments(card) == []
  end

  test "blank comments are not saved" do
    {:ok, card} = Board.create_card(%{title: "Задача"}, "Анна")
    assert {:error, changeset} = Board.create_comment(card, %{body: "  "}, "Борис")
    assert "Заполните поле" in errors_on(changeset).body
    assert Board.list_comments(card) == []
  end
end
