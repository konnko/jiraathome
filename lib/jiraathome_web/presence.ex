defmodule JiraathomeWeb.Presence do
  use Phoenix.Presence,
    otp_app: :jiraathome,
    pubsub_server: Jiraathome.PubSub

  @topic "shared_file:presence"

  def join(name) do
    Phoenix.PubSub.subscribe(Jiraathome.PubSub, @topic)
    track(self(), @topic, name, %{})
  end

  def names, do: @topic |> list() |> Map.keys() |> Enum.sort()
end
