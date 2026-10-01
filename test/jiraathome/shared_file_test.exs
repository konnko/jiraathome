defmodule Jiraathome.SharedFileTest do
  use Jiraathome.DataCase
  alias Jiraathome.SharedFile

  test "updates are persisted, ordered, broadcast and replayed from a sequence" do
    SharedFile.subscribe()
    data = Base.encode64(<<0, 0>>)
    assert {:ok, first} = SharedFile.save("first", data, "Анна")
    assert_receive {:file_updated, ^first}
    assert {:ok, second} = SharedFile.save("second", data, "Борис")
    assert_receive {:file_updated, ^second}
    assert first.sequence < second.sequence
    assert first.author == "Анна"
    assert first.saved_at =~ "МСК"
    assert SharedFile.updates_after(0) == [first, second]
    assert SharedFile.updates_after(first.sequence) == [second]

    assert {:ok, ^first} = SharedFile.save("first", data, "Анна")
    refute_receive {:file_updated, _}
    assert SharedFile.updates_after(0) == [first, second]
  end

  test "concurrent callers receive distinct sequential positions" do
    updates =
      1..10
      |> Task.async_stream(fn n ->
        {:ok, update} = SharedFile.save("batch-#{n}", Base.encode64(<<0, 0>>), "Автор #{n}")
        update
      end)
      |> Enum.map(fn {:ok, update} -> update end)

    persisted = SharedFile.updates_after(0)
    assert length(persisted) == 10
    assert Enum.sort_by(updates, & &1.sequence) == persisted
  end

  test "invalid encoding is rejected without disturbing the queue" do
    assert {:error, :invalid_update} = SharedFile.save("invalid", "!", "Анна")
    assert SharedFile.updates_after(0) == []
  end
end
