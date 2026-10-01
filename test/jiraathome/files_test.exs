defmodule Jiraathome.FilesTest do
  use Jiraathome.DataCase

  use Oban.Testing,
    repo: Jiraathome.Repo,
    engine: Oban.Engines.Lite,
    notifier: Oban.Notifiers.Isolated

  alias Jiraathome.{Board, Documents, Files}
  alias Jiraathome.Files.{Blob, Storage}

  setup do
    directory =
      Path.join(System.tmp_dir!(), "jiraathome-cleanup-#{System.unique_integer([:positive])}")

    File.mkdir_p!(directory)
    Application.put_env(:jiraathome, :uploads_dir, directory)

    on_exit(fn ->
      Application.delete_env(:jiraathome, :uploads_dir)
      File.rm_rf!(directory)
    end)

    :ok
  end

  test "weekly job removes old orphan files from disk and database, retaining fresh uploads" do
    old = file(days_unused: 8)
    fresh = file(days_unused: 0)
    assert :ok = perform_job(Files.UnreferencedFilesCleanupJob, %{})
    refute File.exists?(Storage.path(old))
    assert is_nil(Files.get_file!(old.id, not_found_error?: false))
    assert File.exists?(Storage.path(fresh))
    assert Files.get_file!(fresh.id)
  end

  test "attached files, markdown images and live Yjs images survive cleanup" do
    attachment = file(days_unused: 20)
    markdown = file(days_unused: 20)
    shared = file(days_unused: 20)

    Board.add_card!(:backlog, "Автор", %{
      title: "Files",
      attachment_ids: [attachment.id],
      description: "![image](#{Storage.url(markdown)})"
    })

    doc = Yex.Doc.new()
    fragment = Yex.Doc.get_xml_fragment(doc, "prosemirror")

    :ok =
      Yex.XmlFragment.insert(
        fragment,
        0,
        Yex.XmlElementPrelim.new("image", [], %{"src" => Storage.url(shared)})
      )

    save_doc(doc, "image")

    assert Files.clean_up_unreferenced_files!() == 0

    for item <- [attachment, markdown, shared] do
      assert File.exists?(Storage.path(item))
      assert is_nil(Files.get_file!(item.id).orphaned_at)
    end
  end

  test "detaching starts a grace period and shared references protect the same file" do
    attachment = file(days_unused: 20)
    first = Board.add_card!(:backlog, "Автор", %{title: "First", attachment_ids: [attachment.id]})

    second =
      Board.add_card!(:backlog, "Автор", %{title: "Second", attachment_ids: [attachment.id]})

    Files.clean_up_unreferenced_files!()
    Board.delete_card!(first)
    Files.clean_up_unreferenced_files!()
    assert is_nil(Files.get_file!(attachment.id).orphaned_at)
    Board.edit_card!(second, %{attachment_ids: []})
    assert Files.clean_up_unreferenced_files!() == 0
    assert Files.get_file!(attachment.id).orphaned_at
    assert File.exists?(Storage.path(attachment))
  end

  test "deleted Yjs nodes do not keep files alive through historical updates" do
    image = file(days_unused: 20)
    doc = Yex.Doc.new()
    fragment = Yex.Doc.get_xml_fragment(doc, "prosemirror")

    :ok =
      Yex.XmlFragment.insert(
        fragment,
        0,
        Yex.XmlElementPrelim.new("image", [], %{"src" => Storage.url(image)})
      )

    save_doc(doc, "before-delete")
    :ok = Yex.XmlFragment.delete(fragment, 0, 1)
    save_doc(doc, "after-delete")
    assert Files.clean_up_unreferenced_files!() == 1
    refute File.exists?(Storage.path(image))
  end

  test "a corrupt document aborts cleanup instead of deleting possibly referenced files" do
    file = file(days_unused: 20)
    Documents.append_update!(%{token: "bad", data: <<255>>, author_name: "Автор"})
    assert_raise Ash.Error.Unknown, fn -> Files.clean_up_unreferenced_files!() end
    assert File.exists?(Storage.path(file))
    assert Files.get_file!(file.id)
  end

  test "missing physical files can be cleaned up safely" do
    file = file(days_unused: 20)
    File.rm!(Storage.path(file))
    assert Files.clean_up_unreferenced_files!() == 1
    assert is_nil(Files.get_file!(file.id, not_found_error?: false))
  end

  defp file(days_unused: days) do
    file =
      Ash.Seed.seed!(Blob, %{
        id: Ash.UUID.generate(),
        name: "test.txt",
        content_type: "application/octet-stream",
        size: 4,
        orphaned_at: DateTime.add(DateTime.utc_now(), -days, :day)
      })

    File.write!(Storage.path(file), "test")
    file
  end

  defp save_doc(doc, token) do
    Documents.append_update!(%{
      token: token,
      data: Yex.encode_state_as_update!(doc),
      author_name: "Автор"
    })
  end
end
