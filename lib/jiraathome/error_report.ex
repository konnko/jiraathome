defmodule Jiraathome.ErrorReport do
  @moduledoc "Reports expected application errors without swallowing unexpected failures."
  require Logger

  def log(operation, error), do: Logger.warning("#{operation}: #{Exception.message(error)}")
end
