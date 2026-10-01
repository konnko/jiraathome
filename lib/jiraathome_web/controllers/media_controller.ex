defmodule JiraathomeWeb.MediaController do
  use JiraathomeWeb, :controller
  alias Jiraathome.Files
  alias Jiraathome.Files.Storage

  def create(conn, %{"file" => %Plug.Upload{} = upload}) do
    case Files.store_file(upload) do
      {:ok, media} ->
        json(conn, %{
          id: media.id,
          url: Storage.url(media),
          name: media.name,
          type: media.content_type
        })

      {:error, %Ash.Error.Invalid{} = error} ->
        Jiraathome.ErrorReport.log("upload", error)
        conn |> put_status(413) |> json(%{error: "Максимальный размер файла — 20 МБ"})

      {:error, error} ->
        raise error
    end
  end

  def create(conn, _), do: conn |> put_status(422) |> json(%{error: "Выберите файл"})

  def show(conn, %{"id" => id}) do
    case get_file(id) do
      nil ->
        send_resp(conn, 404, "Файл не найден")

      media ->
        if File.regular?(Storage.path(media)) do
          conn
          |> put_resp_header("cache-control", "private, max-age=86400")
          |> put_resp_header("x-content-type-options", "nosniff")
          |> send_download({:file, Storage.path(media)},
            filename: media.name,
            content_type: media.content_type,
            disposition:
              if(String.starts_with?(media.content_type, "image/"),
                do: :inline,
                else: :attachment
              )
          )
        else
          send_resp(conn, 404, "Файл не найден")
        end
    end
  end

  defp get_file(id) do
    case Ash.Type.cast_input(:uuid, id) do
      {:ok, id} -> Files.get_file!(id, not_found_error?: false)
      _ -> nil
    end
  end
end
