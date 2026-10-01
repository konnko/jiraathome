defmodule JiraathomeWeb.Layouts do
  use JiraathomeWeb, :html
  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_name, :string, required: true
  attr :page, :atom, values: [:board, :file], required: true
  slot :inner_block, required: true

  def workspace(assigns) do
    ~H"""
    <.app flash={@flash}>
      <div id="workspace" class="workspace-page" phx-hook="ImagePreview">
        <header class="page-header">
          <.link navigate={~p"/"} class="wordmark">jiraathome<span aria-hidden="true">.</span></.link>
          <nav class="page-nav" aria-label="Разделы">
            <.link navigate={~p"/"} aria-current={@page == :board && "page"}>Доска задач</.link>
            <.link navigate={~p"/file"} aria-current={@page == :file && "page"}>Общий файл</.link>
          </nav>
          <span class="shared-label">{@current_name}</span>
        </header>
        <div class="workspace-content">{render_slot(@inner_block)}</div>
      </div>
    </.app>
    """
  end

  attr :flash, :map, required: true
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main>{render_slot(@inner_block)}</main>
    <p :if={Phoenix.Flash.get(@flash, :error)} role="alert" class="alert alert-error flash-message">
      {Phoenix.Flash.get(@flash, :error)}
    </p>
    """
  end
end
