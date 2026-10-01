defmodule JiraathomeWeb.Router do
  use JiraathomeWeb, :router
  import JiraathomeWeb.Auth

  pipeline :browser do
    plug :accepts, ["html"]
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

    live_session :board, on_mount: [{JiraathomeWeb.Auth, :default}] do
      live "/", BoardLive
      live "/file", FileLive
    end
  end
end
