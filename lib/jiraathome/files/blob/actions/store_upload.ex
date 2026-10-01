defmodule Jiraathome.Files.Blob.Actions.StoreUpload do
  @moduledoc "Copies the upload out of Plug's temporary directory before the request ends and deletes it."
  use Ash.Resource.Actions.Implementation
  alias Jiraathome.Files
  alias Jiraathome.Files.Storage

  @impl true
  def run(input, _opts, _context) do
    upload = input.arguments.upload
    id = Ash.UUID.generate()
    File.mkdir_p!(Storage.directory())
    File.cp!(upload.path, Storage.path(%{id: id}))

    Files.register_stored_file(%{
      id: id,
      name: Path.basename(upload.filename),
      size: File.stat!(upload.path).size,
      content_type: Storage.image_type(upload.path)
    })
  end
end
