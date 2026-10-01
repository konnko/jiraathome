defmodule Jiraathome.Repo do
  use AshSqlite.Repo, otp_app: :jiraathome
  @impl true
  def write_transactions?, do: true
end
