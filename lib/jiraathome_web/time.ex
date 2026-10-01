defmodule JiraathomeWeb.Time do
  @moduledoc "Formatting application timestamps in Moscow time (UTC+03:00)."

  def moscow(%DateTime{} = timestamp) do
    timestamp
    |> DateTime.add(3 * 60 * 60, :second)
    |> Calendar.strftime("%d.%m.%Y %H:%M МСК")
  end
end
