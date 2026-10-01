defmodule JiraathomeWeb.SessionController do
  use JiraathomeWeb, :controller

  def new(conn, _params) do
    if JiraathomeWeb.Auth.authenticated?(get_session(conn)) do
      redirect(conn, to: ~p"/")
    else
      render(conn, :new, name: "", name_error: nil, error: nil)
    end
  end

  def create(conn, %{"password" => password} = params) do
    name = String.trim(params["name"] || "")

    cond do
      name == "" ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:new, name: name, name_error: "Введите имя", error: nil)

      JiraathomeWeb.Auth.valid_password?(password) ->
        conn
        |> configure_session(renew: true)
        |> put_session(:authenticated, true)
        |> put_session(:name, name)
        |> redirect(to: ~p"/")

      true ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:new, name: name, name_error: nil, error: "Неверный пароль")
    end
  end
end
