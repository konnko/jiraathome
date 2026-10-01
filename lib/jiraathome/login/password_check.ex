defmodule Jiraathome.Login.PasswordCheck do
  @moduledoc "Rate-limited password checks, keyed by the connection's client IP."
  use Ash.Resource, domain: Jiraathome.Login, extensions: [AshRateLimiter]
  alias Jiraathome.Login.PasswordCheck.Actions

  rate_limit do
    backend(Jiraathome.RateLimiter)
    action :check, limit: 3, per: :timer.hours(1), key: &__MODULE__.rate_limit_key/1
  end

  actions do
    action :check, :boolean do
      description "Сравнивает пароль с общим. После трёх попыток за час с одного IP — Forbidden."
      argument :ip, :string, allow_nil?: false
      argument :password, :string, allow_nil?: false, sensitive?: true
      run Actions.CompareWithSharedPassword
    end
  end

  def rate_limit_key(input), do: "login:" <> input.arguments.ip
end
