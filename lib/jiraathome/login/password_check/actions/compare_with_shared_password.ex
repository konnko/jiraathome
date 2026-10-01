defmodule Jiraathome.Login.PasswordCheck.Actions.CompareWithSharedPassword do
  @moduledoc "Compares hashes in constant time so the response time does not leak the password."
  use Ash.Resource.Actions.Implementation

  @impl true
  def run(input, _opts, _context) do
    expected = Application.fetch_env!(:jiraathome, :password)

    {:ok,
     Plug.Crypto.secure_compare(
       :crypto.hash(:sha256, input.arguments.password),
       :crypto.hash(:sha256, expected)
     )}
  end
end
