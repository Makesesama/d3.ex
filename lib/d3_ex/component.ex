defmodule D3Ex.Component do
  @moduledoc """
  Component behavior for building D3.js visualizations on top of LiveView.

  `D3Ex.Component` is a thin shell that handles the boilerplate of putting a
  D3 hook on the page: it generates a DOM id, merges your defaults with caller
  assigns, and provides helpers to JSON-encode data/config/events into
  `data-*` attributes the JS hook can read.

  You write two things:

    1. A module that `use D3Ex.Component`, implements `default_config/0`,
       `prepare_assigns/1`, and `render/1`.
    2. A JS hook (typically with `createD3Hook`) that owns the D3 rendering.

  ## Example

      defmodule MyApp.D3.PieChart do
        use D3Ex.Component

        @impl true
        def default_config do
          %{width: 480, height: 480, inner_radius: 0}
        end

        @impl true
        def prepare_assigns(assigns) do
          assigns
          |> Map.put_new(:initial_data, [])
          |> Map.put_new(:value_key, :value)
          |> Map.put_new(:on_slice_click, nil)
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div
            id={@id}
            phx-hook="D3PieChart"
            data-items={encode_data(@initial_data)}
            data-config={encode_config(Map.put(@config, :value_key, @value_key))}
            data-events={encode_events(%{on_slice_click: @on_slice_click})}
            phx-update="ignore"
            style={"width: \#{@config.width}px; height: \#{@config.height}px;"}
          >
            <svg width={@config.width} height={@config.height}></svg>
          </div>
          \"\"\"
        end
      end

  After `import MyApp.D3.PieChart`, use it as `<.pie_chart ... />`. The
  function name is derived from the module's last segment.

  ## Top-level config keys

  Any top-level assign whose key matches a key in `default_config/0` is merged
  into `@config`. So callers can write either:

      <.pie_chart width={600} inner_radius={50} />

  or:

      <.pie_chart config={%{width: 600, inner_radius: 50}} />

  Top-level wins over the `:config` map.

  ## Helpers in scope

  After `use D3Ex.Component`:

    * `ensure_id/1`        — generate a DOM id if not provided
    * `encode_data/1`      — `Jason.encode!/1`
    * `encode_config/1`    — `Jason.encode!/1`
    * `encode_events/1`    — encodes a `%{slot => handler_name}` map, dropping nils
    * `merge_config/2`     — merges defaults + caller config + top-level keys
  """

  @doc "Default configuration map for the component."
  @callback default_config() :: map()

  @doc "Normalize assigns before render — apply defaults, validate, etc."
  @callback prepare_assigns(assigns :: map()) :: map()

  @doc "Render the component's HEEx template."
  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  @optional_callbacks [default_config: 0, prepare_assigns: 1]

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component
      import D3Ex.Component

      @behaviour D3Ex.Component

      @doc "Renders this component."
      def component(assigns) do
        assigns
        |> ensure_id()
        |> merge_config(default_config())
        |> prepare_assigns()
        |> render()
      end

      @doc false
      def default_config, do: %{}

      @doc false
      def prepare_assigns(assigns), do: assigns

      defoverridable default_config: 0, prepare_assigns: 1

      @before_compile D3Ex.Component
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    # Define a function named after the module's last segment so callers can
    # write `<.bar_chart ... />` after `import MyApp.D3.BarChart`.
    name =
      env.module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()
      |> String.to_atom()

    quote do
      @doc "Alias for `component/1` named after the module."
      def unquote(name)(assigns), do: component(assigns)
    end
  end

  @doc "Generate a unique DOM id if not provided."
  def ensure_id(assigns) do
    Map.put_new_lazy(assigns, :id, fn ->
      "d3ex-#{:erlang.unique_integer([:positive])}"
    end)
  end

  @doc "JSON-encode data for a `data-*` attribute."
  def encode_data(data), do: Jason.encode!(data)

  @doc "JSON-encode config for a `data-*` attribute."
  def encode_config(config), do: Jason.encode!(config)

  @doc """
  Encode a `%{slot => handler_name}` map for `data-events`, dropping nil
  handlers. The hook reads this map once at mount and uses it to resolve
  `sendEvent` calls to LiveView event names.

      <div data-events={encode_events(%{
        on_bar_click: @on_bar_click,
        on_bar_hover: @on_bar_hover
      })}>
  """
  def encode_events(events) do
    events
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
    |> Jason.encode!()
  end

  @doc """
  Merge `defaults` + the caller's `:config` map + any top-level assigns whose
  keys also appear in `defaults`. Top-level wins over `:config`; `:config`
  wins over defaults.
  """
  def merge_config(assigns, defaults) do
    user_config = Map.get(assigns, :config, %{})

    top_level =
      defaults
      |> Map.keys()
      |> Enum.reduce(%{}, fn key, acc ->
        case Map.get(assigns, key) do
          nil -> acc
          value -> Map.put(acc, key, value)
        end
      end)

    merged =
      defaults
      |> Map.merge(user_config)
      |> Map.merge(top_level)

    Map.put(assigns, :config, merged)
  end
end
