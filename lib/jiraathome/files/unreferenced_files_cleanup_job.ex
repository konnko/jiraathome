defmodule Jiraathome.Files.UnreferencedFilesCleanupJob do
  use Oban.Worker, queue: :maintenance, max_attempts: 3, unique: [period: 3600]

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Jiraathome.Files.clean_up_unreferenced_files!()
    :ok
  end
end
