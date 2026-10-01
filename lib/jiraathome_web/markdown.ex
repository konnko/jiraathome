defmodule JiraathomeWeb.Markdown do
  @moduledoc "Render the Markdown stored in card descriptions."

  def html(markdown) do
    MDEx.to_html!(markdown || "",
      extension: [table: true, strikethrough: true, tasklist: true, autolink: true],
      render: [escape: true],
      syntax_highlight: false,
      sanitize: [
        add_tags: ["input"],
        add_tag_attributes: %{"input" => ["type", "checked", "disabled"]}
      ]
    )
  end
end
