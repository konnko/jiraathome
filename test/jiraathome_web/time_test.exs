defmodule JiraathomeWeb.TimeTest do
  use ExUnit.Case, async: true

  test "Moscow time crosses the UTC date boundary" do
    assert JiraathomeWeb.Time.moscow(~U[2026-10-01 22:15:00Z]) == "02.10.2026 01:15 МСК"
  end
end
