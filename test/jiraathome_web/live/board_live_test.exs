defmodule JiraathomeWeb.BoardLiveTest do
  use JiraathomeWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Jiraathome.Board

  setup %{conn: conn} do
    %{conn: init_test_session(conn, authenticated: true, name: "Анна")}
  end

  test "create, edit, move and delete from the board", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    view |> element("#column-backlog .add-card") |> render_click()

    view
    |> form("#card-form", card: %{title: "Первая", description: "Описание", status: "backlog"})
    |> render_submit()

    [card] = Board.list_cards()
    assert card.author_name == "Анна"
    assert has_element?(view, "#column-backlog #card-#{card.id}", "Первая")

    view |> element("#card-#{card.id} .card-content") |> render_click()

    view
    |> form("#card-form",
      card: %{title: "Обновлено", description: "Новые детали", status: "researching"}
    )
    |> render_submit()

    assert has_element?(view, "#column-researching #card-#{card.id}", "Новые детали")

    render_hook(view, "move", %{card_id: card.id, status: "doing"})

    assert has_element?(view, "#column-doing #card-#{card.id}")
    render_hook(view, "move", %{card_id: card.id, status: "done"})
    assert has_element?(view, "#column-done #card-#{card.id}")

    view |> element("#card-#{card.id} .card-content") |> render_click()
    view |> element("#delete-card") |> render_click()
    refute has_element?(view, "#card-#{card.id}")
    assert [] = Board.list_cards()
  end

  test "validation keeps the editor open and cancel saves nothing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    view |> element("#column-doing .add-card") |> render_click()
    assert has_element?(view, "#card_status option[value=doing][selected]")
    view |> form("#card-form", card: %{title: "   "}) |> render_submit()
    assert has_element?(view, "#card-form", "Заполните поле")
    assert Board.list_cards() == []
    render_click(view, "cancel")
    refute has_element?(view, "#card-editor")
  end

  test "other viewers receive updates without losing their draft", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    {:ok, other, _html} = live(conn, ~p"/")
    other |> element("#column-backlog .add-card") |> render_click()
    view |> element("#column-backlog .add-card") |> render_click()
    view |> form("#card-form", card: %{title: "Общая карточка"}) |> render_submit()
    assert render(other) =~ "Общая карточка"
    assert has_element?(other, "#card-editor")
  end

  test "comments use the session name and update another viewer's open card", %{conn: conn} do
    {:ok, card} = Board.create_card(%{title: "Общая задача"}, "Создатель")
    {:ok, view, _html} = live(conn, ~p"/")
    other_conn = init_test_session(build_conn(), authenticated: true, name: "Борис")
    {:ok, other, _html} = live(other_conn, ~p"/")

    for viewer <- [view, other] do
      viewer |> element("#card-#{card.id} .card-content") |> render_click()
      assert has_element?(viewer, ".editor-author", "Создатель")
    end

    view |> form("#comment-form", comment: %{body: "Первый комментарий"}) |> render_change()
    view |> form("#comment-form", comment: %{body: "Первый комментарий"}) |> render_submit()
    [comment] = Board.list_comments(card)
    assert comment.author_name == "Анна"
    refute view |> element("#comment_body") |> render() =~ "Первый комментарий"
    assert has_element?(other, "#comment-#{comment.id}", "Первый комментарий")
    assert has_element?(other, "#comment-#{comment.id}", "Анна")

    other |> form("#comment-form", comment: %{body: "Ответ"}) |> render_submit()
    assert Enum.map(Board.list_comments(card), & &1.author_name) == ["Анна", "Борис"]
    assert has_element?(view, "#comments", "Ответ")

    other |> form("#card-form", card: %{title: "Правка Бориса"}) |> render_submit()
    assert Board.get_card!(card.id).author_name == "Создатель"
  end

  test "blank comment shows validation and saves nothing", %{conn: conn} do
    {:ok, card} = Board.create_card(%{title: "Задача"}, "Анна")
    {:ok, view, _html} = live(conn, ~p"/")
    view |> element("#card-#{card.id} .card-content") |> render_click()
    view |> form("#comment-form", comment: %{body: "   "}) |> render_submit()
    assert has_element?(view, "#comment-form", "Заполните поле")
    assert Board.list_comments(card) == []
  end

  test "rich descriptions render on the board and round-trip through validation and editing", %{
    conn: conn
  } do
    markdown = "## План\n\n**Важно**\n\n- Первый пункт\n\n[Документ](https://example.com)"
    {:ok, view, _} = live(conn, ~p"/")
    view |> element("#column-backlog .add-card") |> render_click()
    view |> form("#card-form", card: %{title: " ", description: markdown}) |> render_submit()
    assert has_element?(view, "#card-form", "Заполните поле")
    assert has_element?(view, "#card-description-editor")
    assert Board.list_cards() == []
    view |> form("#card-form", card: %{title: "План", description: markdown}) |> render_submit()
    [card] = Board.list_cards()
    assert card.description == markdown
    assert has_element?(view, "#card-#{card.id} .markdown-content h2", "План")
    assert has_element?(view, "#card-#{card.id} .markdown-content strong", "Важно")
    assert has_element?(view, "#card-#{card.id} .markdown-content li", "Первый пункт")

    assert has_element?(
             view,
             "#card-#{card.id} .markdown-content a[href='https://example.com']",
             "Документ"
           )

    refute has_element?(view, "#card-#{card.id} .card-content a")
    view |> element("#card-#{card.id} .card-content") |> render_click()
    assert has_element?(view, "#card-description-editor[phx-hook=CardDescription]")
    assert has_element?(view, "#card_description", "**Важно**")
    view |> form("#card-form", card: %{title: "Изменён заголовок"}) |> render_submit()
    assert Board.get_card!(card.id).description == markdown
  end
end
