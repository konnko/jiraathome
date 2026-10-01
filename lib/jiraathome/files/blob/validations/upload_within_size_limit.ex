defmodule Jiraathome.Files.Blob.Validations.UploadWithinSizeLimit do
  @moduledoc "Keeps single uploads under 20 MB so the shared volume is not filled by one file."
  use Ash.Resource.Validation

  @max_bytes 20 * 1024 * 1024

  @impl true
  def supports(_opts), do: [Ash.ActionInput]

  @impl true
  def validate(input, _opts, _context) do
    if File.stat!(input.arguments.upload.path).size > @max_bytes do
      {:error, field: :upload, message: "Максимальный размер файла — 20 МБ"}
    else
      :ok
    end
  end
end
