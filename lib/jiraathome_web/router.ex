defmodule JiraathomeWeb.Router do
  @moduledoc false
  use JiraathomeWeb, :router
  import JiraathomeWeb.Auth

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JiraathomeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticated do
    plug :require_password
  end

  scope "/", JiraathomeWeb do
    pipe_through :browser
    get "/login", SessionController, :new
    post "/login", SessionController, :create
  end

  scope "/", JiraathomeWeb do
    pipe_through [:browser, :authenticated]

    post "/media", MediaController, :create
    get "/media/:id", MediaController, :show

    live_session :board, on_mount: [{JiraathomeWeb.Auth, :default}] do
      live "/", BoardLive
      live "/file", FileLive
    end
  end
end
