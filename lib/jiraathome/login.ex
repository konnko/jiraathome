defmodule Jiraathome.Login do
  @moduledoc "Access to the workspace through the shared password."
  use Ash.Domain, otp_app: :jiraathome

  resources do
    resource Jiraathome.Login.PasswordCheck do
      define :check_password, action: :check, args: [:ip, :password]
    end
  end
end
