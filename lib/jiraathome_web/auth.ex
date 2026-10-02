defmodule JiraathomeWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def require_password(conn, _opts) do
    if authenticated?(get_session(conn)) do
      # Refresh the persistent browser cookie; the signed session has no server-side expiry.
      configure_session(conn, renew: true)
    else
      # Remember the requested page so a shared card link opens after logging in.
      conn
      |> put_session(:return_to, current_path(conn))
      |> redirect(to: "/login")
      |> halt()
    end
  end

  def on_mount(:default, _params, session, socket) do
    if authenticated?(session) do
      {:cont, Phoenix.Component.assign(socket, :current_name, session["name"])}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/login")}
    end
  end

  def authenticated?(%{"authenticated" => true, "name" => name}) when is_binary(name) do
    String.trim(name) != ""
  end

  def authenticated?(_session), do: false
end
