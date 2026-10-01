defmodule Jiraathome.Files.Cleanup do
  use Ash.Resource.Actions.Implementation
  alias Jiraathome.{Board, Documents, Files}

  @impl true
  def run(_input, _opts, _context) do
    Ash.transact([Jiraathome.Board.Card, Jiraathome.SharedFile.Update, Files.Blob], fn ->
      references = referenced_file_ids()
      cutoff = DateTime.add(DateTime.utc_now(), -7, :day)

      deleted =
        Enum.count(Files.list_files!(), fn file ->
          cond do
            MapSet.member?(references, file.id) ->
              if file.orphaned_at, do: Files.mark_used!(file)
              false

            is_nil(file.orphaned_at) ->
              Files.mark_orphaned!(file)
              false

            DateTime.compare(file.orphaned_at, cutoff) == :lt ->
              Files.delete_file!(file)
              true

            true ->
              false
          end
        end)

      deleted
    end)
  end

  defp referenced_file_ids do
    cards = Board.list_cards!()
    doc = Yex.Doc.new()
    # Replay the CRDT, including deletions. Historical update bytes are not live references.
    for update <- Documents.updates_after!(0), do: :ok = Yex.apply_update(doc, update.data)
    document = doc |> Yex.Doc.get_xml_fragment("prosemirror") |> Yex.XmlFragment.to_string()
    text = Enum.map_join(cards, "\n", &(&1.description || "")) <> "\n" <> document

    inline_ids =
      Regex.scan(~r"/media/([0-9a-fA-F-]{36})", text, capture: :all_but_first) |> List.flatten()

    MapSet.new(inline_ids ++ Enum.flat_map(cards, & &1.attachment_ids))
  end
end
