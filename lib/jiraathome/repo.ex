defmodule Jiraathome.Repo do
  use Ecto.Repo,
    otp_app: :jiraathome,
    adapter: Ecto.Adapters.SQLite3
end
