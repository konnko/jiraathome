defmodule Jiraathome.Files.Store do
  use Ash.Resource.Actions.Implementation
  alias Jiraathome.Files
  alias Jiraathome.Files.Storage

  @impl true
  def run(input, _opts, _context) do
    upload = input.arguments.upload
    stat = File.stat!(upload.path)

    if stat.size > 20 * 1024 * 1024 do
      {:error,
       Ash.Error.Action.InvalidArgument.exception(
         field: :upload,
         message: "Максимальный размер файла — 20 МБ"
       )}
    else
      File.mkdir_p!(Storage.directory())
      id = Ash.UUID.generate()
      destination = Storage.path(%{id: id})
      File.cp!(upload.path, destination)

      case Files.register_file(%{
             id: id,
             name: Path.basename(upload.filename),
             size: stat.size,
             content_type: Storage.image_type(upload.path)
           }) do
        {:ok, file} ->
          {:ok, file}

        {:error, error} ->
          File.rm!(destination)
          {:error, error}
      end
    end
  end
end
