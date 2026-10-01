defmodule JiraathomeWeb.SessionControllerTest do
  use JiraathomeWeb.ConnCase

  test "the board redirects visitors to login", %{conn: conn} do
    assert conn |> get(~p"/") |> redirected_to() == ~p"/login"
  end

  test "incorrect password does not grant access", %{conn: conn} do
    conn = post(conn, ~p"/login", %{password: "wrong", name: "Анна"})
    assert html_response(conn, 422) =~ "Неверный пароль"
    refute get_session(conn, :authenticated)
  end

  test "login persists in a signed cookie across requests", %{conn: conn} do
    conn = post(conn, ~p"/login", %{password: "test-password", name: "  Анна  "})
    assert redirected_to(conn) == ~p"/"
    assert get_session(conn, :authenticated)
    assert get_session(conn, :name) == "Анна"
    cookie = conn.resp_cookies["_jiraathome_key"]
    assert cookie.max_age == 34_560_000
    assert cookie.http_only
    assert cookie.same_site == "Lax"
    refute cookie.value =~ "test-password"

    conn = conn |> recycle() |> get(~p"/")
    assert html_response(conn, 200) =~ "Доска задач"
    assert conn.resp_cookies["_jiraathome_key"].max_age == 34_560_000
    assert conn |> recycle() |> get(~p"/login") |> redirected_to() == ~p"/"
  end

  test "a tampered session does not grant access", %{conn: conn} do
    conn = conn |> put_req_cookie("_jiraathome_key", "authenticated=true") |> get(~p"/")
    assert redirected_to(conn) == ~p"/login"
  end

  test "an existing login survives the application rename", %{conn: conn} do
    signed_in = post(conn, ~p"/login", %{password: "test-password", name: "Анна"})
    cookie = signed_in.resp_cookies["_jiraathome_key"].value

    migrated = build_conn() |> put_req_cookie("_pochetasks_key", cookie) |> get(~p"/")
    assert html_response(migrated, 200) =~ "Анна"
    assert migrated.resp_cookies["_jiraathome_key"].value
    assert migrated.resp_cookies["_pochetasks_key"].max_age == 0
  end

  test "LiveView also checks authentication" do
    assert {:halt, socket} =
             JiraathomeWeb.Auth.on_mount(:default, %{}, %{}, %Phoenix.LiveView.Socket{})

    assert {:redirect, %{to: "/login"}} = socket.redirected
  end

  test "a nonblank name is required", %{conn: conn} do
    conn = post(conn, ~p"/login", %{password: "test-password", name: "  "})
    assert html_response(conn, 422) =~ "Введите имя"
    refute get_session(conn, :authenticated)
  end

  test "sessions without a name must sign in again", %{conn: conn} do
    conn = init_test_session(conn, authenticated: true)
    assert conn |> get(~p"/") |> redirected_to() == ~p"/login"
    assert conn |> get(~p"/login") |> html_response(200) =~ "Ваше имя"

    assert {:halt, _socket} =
             JiraathomeWeb.Auth.on_mount(
               :default,
               %{},
               %{"authenticated" => true},
               %Phoenix.LiveView.Socket{}
             )
  end
end
