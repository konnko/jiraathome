defmodule JiraathomeWeb.CoreComponents do
  use Phoenix.Component

  attr :field, Phoenix.HTML.FormField, default: nil
  attr :name, :string
  attr :id, :string, default: nil
  attr :value, :any, default: nil
  attr :type, :string, default: "text"
  attr :label, :string, required: true
  attr :options, :list, default: []
  attr :errors, :list, default: []
  attr :rest, :global, include: ~w(required autofocus autocomplete placeholder rows maxlength)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(
      field: nil,
      id: field.id,
      name: field.name,
      value: field.value,
      errors: Enum.map(errors, fn {message, _opts} -> message end)
    )
    |> input()
  end

  def input(assigns) do
    ~H"""
    <div class="form-field">
      <label for={@id || @name} class="field-label">{@label}</label>
      <textarea
        :if={@type == "textarea"}
        id={@id || @name}
        name={@name}
        class="textarea w-full"
        aria-invalid={@errors != []}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <select
        :if={@type == "select"}
        id={@id || @name}
        name={@name}
        class="select w-full"
        aria-invalid={@errors != []}
        {@rest}
      >
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <input
        :if={@type not in ["textarea", "select"]}
        id={@id || @name}
        name={@name}
        type={@type}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class="input w-full"
        aria-invalid={@errors != []}
        {@rest}
      />
      <p :for={error <- @errors} class="field-error" role="alert">{error}</p>
    </div>
    """
  end
end
