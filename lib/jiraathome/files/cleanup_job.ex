defmodule Jiraathome.Files.CleanupJob do
  use Oban.Worker, queue: :maintenance, max_attempts: 3, unique: [period: 3600]

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Jiraathome.Files.cleanup_unused_files!()
    :ok
  end
end
