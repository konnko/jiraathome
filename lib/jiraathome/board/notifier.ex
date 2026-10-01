defmodule Jiraathome.Board.Notifier do
  use Ash.Notifier

  @impl true
  def notify(_notification) do
    Phoenix.PubSub.broadcast(Jiraathome.PubSub, "board", :board_updated)
  end
end
