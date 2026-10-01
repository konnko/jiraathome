defmodule JiraathomeWeb.MarkdownTest do
  use ExUnit.Case, async: true
  alias JiraathomeWeb.Markdown

  test "formats the Markdown emitted by the editor" do
    html =
      Markdown.html("""
      ## План

      **Жирный** и *курсив*, ~~зачёркнутый~~, `код`.

      - пункт
      - [x] готово

      [Ссылка](https://example.com)

      | A | B |
      | - | - |
      | 1 | 2 |

      ```elixir
      IO.puts("hello")
      ```
      """)

    for tag <- ["<h2>", "<strong>", "<em>", "<del>", "<code>", "<ul>", "<table>", "<pre>"] do
      assert html =~ tag
    end

    assert html =~ ~s(href="https://example.com")
    assert html =~ ~s(type="checkbox")
    assert html =~ "checked"
  end

  test "does not execute raw HTML, event handlers or javascript links" do
    html =
      Markdown.html(
        "<script>alert(1)</script>\n\n<img src=x onerror=alert(1)>\n\n[x](javascript:alert(1))"
      )

    refute html =~ "<script"
    refute html =~ "<img src=x"
    refute html =~ ~s(href="javascript:)
  end

  test "empty and old plain descriptions remain valid" do
    assert Markdown.html(nil) == ""
    assert Markdown.html("Простое описание") =~ "<p>Простое описание</p>"
  end
end
