defmodule JiraathomeWeb.MediaControllerTest do
  use JiraathomeWeb.ConnCase
  alias Jiraathome.Files
  alias Jiraathome.Files.Storage

  setup %{conn: conn} do
    dir = Path.join(System.tmp_dir!(), "jiraathome-media-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    Application.put_env(:jiraathome, :uploads_dir, Path.join(dir, "stored"))

    on_exit(fn ->
      Application.delete_env(:jiraathome, :uploads_dir)
      File.rm_rf!(dir)
    end)

    %{conn: init_test_session(conn, authenticated: true, name: "Анна"), dir: dir}
  end

  test "uploads persist on disk and authenticated downloads retain their contents", %{
    conn: conn,
    dir: dir
  } do
    source = Path.join(dir, "source.txt")
    File.write!(source, "attachment contents")
    upload = %Plug.Upload{path: source, filename: "notes.txt", content_type: "text/plain"}

    response =
      conn
      |> put_req_header("accept", "application/json")
      |> post("/media", %{file: upload})
      |> json_response(200)

    File.rm!(source)
    media = Files.get_file!(response["id"])
    assert File.read!(Storage.path(media)) == "attachment contents"
    download = get(conn, response["url"])
    assert response(download, 200) == "attachment contents"
    assert get_resp_header(download, "content-disposition") |> hd() =~ "attachment"
    assert build_conn() |> get(response["url"]) |> redirected_to() == "/login"
    assert build_conn() |> post("/media", %{file: upload}) |> redirected_to() == "/login"
  end

  test "image type is determined by contents, never by upload headers", %{conn: conn, dir: dir} do
    source = Path.join(dir, "source")
    File.write!(source, "<svg onload='alert(1)'></svg>")
    upload = %Plug.Upload{path: source, filename: "image.svg", content_type: "image/png"}
    result = conn |> post("/media", %{file: upload}) |> json_response(200)
    assert result["type"] == "application/octet-stream"

    assert get_resp_header(get(conn, result["url"]), "content-disposition") |> hd() =~
             "attachment"
  end

  test "oversized uploads and invalid IDs are rejected", %{conn: conn, dir: dir} do
    source = Path.join(dir, "large")

    File.open!(source, [:write], fn file ->
      :file.position(file, 20 * 1024 * 1024)
      IO.binwrite(file, <<0>>)
    end)

    upload = %Plug.Upload{
      path: source,
      filename: "large.bin",
      content_type: "application/octet-stream"
    }

    assert conn |> post("/media", %{file: upload}) |> json_response(413)
    assert conn |> get("/media/invalid") |> response(404)
  end
end
