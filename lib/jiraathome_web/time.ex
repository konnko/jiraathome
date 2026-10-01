defmodule JiraathomeWeb.Time do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :timestamp, DateTime, required: true

  def local(assigns) do
    ~H"""
    <time id={@id} datetime={DateTime.to_iso8601(@timestamp)} phx-hook="LocalTime">
      {Calendar.strftime(@timestamp, "%d.%m.%y %H:%M UTC")}
    </time>
    """
  end
end
