defmodule Jiraathome.Board.Changes.PlaceInColumn do
  @moduledoc """
  Sets `position` so the card lands at the `index` argument among the other cards
  of its column. Positions are floats, so only the moved card is rewritten.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      status = Ash.Changeset.get_attribute(changeset, :status)
      index = Ash.Changeset.get_argument(changeset, :index)

      positions =
        status
        |> Jiraathome.Board.list_column_cards!()
        |> Enum.reject(&(&1.id == changeset.data.id))
        |> Enum.map(& &1.position)

      Ash.Changeset.force_change_attribute(changeset, :position, position_at(positions, index))
    end)
  end

  defp position_at([], _index), do: 0.0
  defp position_at([first | _], 0), do: first - 1

  defp position_at(positions, index) when index >= length(positions),
    do: List.last(positions) + 1

  defp position_at(positions, index),
    do: (Enum.at(positions, index - 1) + Enum.at(positions, index)) / 2
end
