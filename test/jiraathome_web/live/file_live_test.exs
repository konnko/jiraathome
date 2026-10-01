defmodule JiraathomeWeb.FileLiveTest do
  use JiraathomeWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Jiraathome.SharedFile

  test "the shared file requires login", %{conn: conn} do
    assert conn |> get(~p"/file") |> redirected_to() == ~p"/login"
  end

  test "two named viewers see presence and receive updates", %{conn: conn} do
    anna = init_test_session(conn, authenticated: true, name: "Анна")
    boris = init_test_session(build_conn(), authenticated: true, name: "Борис")
    {:ok, a, _} = live(anna, ~p"/file")
    {:ok, b, _} = live(boris, ~p"/file")
    assert has_element?(b, "#file-presence", "Анна")
    assert has_element?(b, "#file-presence", "Борис")

    render_hook(a, "file_save", %{
      token: "browser-batch",
      data: Base.encode64(<<0, 0>>),
      author: "Подмена"
    })

    [update] = SharedFile.updates_after(0)
    assert update.author == "Анна"
    assert_push_event(b, "file_update", ^update)
    assert has_element?(a, "#shared-file[phx-hook=SharedFile]")
    assert has_element?(a, "a[href='/']", "Доска задач")
  end
end
