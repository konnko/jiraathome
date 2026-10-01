defmodule Jiraathome.Login do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(Jiraathome.LoginAttempt)
  end

  def check_password(ip, password) do
    Jiraathome.LoginAttempt
    |> Ash.ActionInput.for_action(:check, %{ip: to_string(:inet.ntoa(ip)), password: password})
    |> Ash.run_action()
    |> case do
      {:ok, valid?} ->
        {:ok, valid?}

      {:error, error} ->
        if Enum.any?(
             Ash.Error.to_error_class(error).errors,
             &match?(%AshRateLimiter.LimitExceeded{}, &1)
           ) do
          {:error, :rate_limited}
        else
          {:error, error}
        end
    end
  end
end
