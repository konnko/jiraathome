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

    if name == "" do
      conn
      |> put_status(:unprocessable_entity)
      |> render(:new, name: name, name_error: "Введите имя", error: nil)
    else
      case Jiraathome.Login.check_password(to_string(:inet.ntoa(conn.remote_ip)), password) do
        {:ok, true} ->
          return_to = get_session(conn, :return_to) || ~p"/"

          conn
          |> configure_session(renew: true)
          |> delete_session(:return_to)
          |> put_session(:authenticated, true)
          |> put_session(:name, name)
          |> redirect(to: return_to)

        {:ok, false} ->
          conn
          |> put_status(:unprocessable_entity)
          |> render(:new, name: name, name_error: nil, error: "Неверный пароль")

        {:error, %Ash.Error.Forbidden{errors: [%AshRateLimiter.LimitExceeded{}]}} ->
          conn
          |> put_resp_header("retry-after", "3600")
          |> put_status(:too_many_requests)
          |> render(:new,
            name: name,
            name_error: nil,
            error: "Слишком много попыток. Доступно 3 попытки в час. Попробуйте позже."
          )
      end
    end
  end
end
