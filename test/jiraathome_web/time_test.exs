defmodule JiraathomeWeb.TimeTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  test "timestamps retain UTC for client-side localization" do
    html =
      render_component(&JiraathomeWeb.Time.local/1,
        id: "time",
        timestamp: ~U[2026-10-01 22:15:00Z]
      )

    assert html =~ ~s(datetime="2026-10-01T22:15:00Z")
    assert html =~ ~s(phx-hook="LocalTime")
  end
end
