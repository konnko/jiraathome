defmodule JiraathomeWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def valid_password?(password) do
    expected = Application.fetch_env!(:jiraathome, :password)
    Plug.Crypto.secure_compare(:crypto.hash(:sha256, password), :crypto.hash(:sha256, expected))
  end

  def require_password(conn, _opts) do
    if authenticated?(get_session(conn)) do
      # Refresh the persistent browser cookie; the signed session has no server-side expiry.
      configure_session(conn, renew: true)
    else
      conn |> redirect(to: "/login") |> halt()
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
