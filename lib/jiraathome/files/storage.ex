defmodule Jiraathome.Files.Storage do
  @moduledoc "Local files in the same persistent volume as SQLite."
  alias Jiraathome.Repo

  def directory do
    Application.get_env(:jiraathome, :uploads_dir) ||
      Path.join(Path.dirname(Repo.config()[:database]), "uploads")
  end

  def path(media), do: Path.join(directory(), media.id)
  def url(media), do: "/media/" <> media.id

  # Only recognized raster images are served inline. Other files are downloads.
  def image_type(path) do
    File.open!(path, [:read, :binary], fn file ->
      case IO.binread(file, 16) do
        <<137, 80, 78, 71, 13, 10, 26, 10, _::binary>> -> "image/png"
        <<255, 216, 255, _::binary>> -> "image/jpeg"
        <<"GIF8", _::binary>> -> "image/gif"
        <<"RIFF", _::binary-size(4), "WEBP", _::binary>> -> "image/webp"
        _ -> "application/octet-stream"
      end
    end)
  end
end
