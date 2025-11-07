defmodule D3Ex.Component do
  @moduledoc """
  Base component behavior for creating custom D3.js visualizations.

  This module provides the foundation for building any D3 visualization
  component. Users can create their own components by using this module
  and implementing the required callbacks.

  ## Creating a Custom Component

  To create a custom D3 visualization:

  1. Create a new module and use `D3Ex.Component`
  2. Implement the `render/1` callback to define your component's template
  3. Create a corresponding JavaScript hook (optional for custom behavior)
  4. Configure default options via `default_config/0` callback (optional)

  ## Example: Custom Pie Chart

      defmodule MyApp.D3Components.PieChart do
        use D3Ex.Component

        @impl true
        def default_config do
          %{
            width: 500,
            height: 500,
            inner_radius: 0,
            color_scheme: "schemeCategory10"
          }
        end

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <div
            id={@id}
            phx-hook="D3PieChart"
            data-config={encode_config(@config)}
            data-items={encode_data(@data)}
            class="d3-pie-chart"
          >
            <svg></svg>
          </div>
          \"\"\"
        end
      end

  Then create the corresponding JavaScript hook in `assets/js/hooks/pie_chart.js`:

      export const D3PieChart = {
        mounted() {
          this.chart = new PieChartD3(this.el, this.getConfig());
          this.chart.render(this.getData());
        },

        updated() {
          this.chart.update(this.getData());
        },

        getConfig() {
          return JSON.parse(this.el.dataset.config);
        },

        getData() {
          return JSON.parse(this.el.dataset.items);
        }
      };

  ## Data Flow

  1. **Mount**: LiveView renders component with initial data
  2. **Initialize**: JS Hook reads data attributes and creates D3 visualization
  3. **Update**: When LiveView assigns change, hook receives `updated()` callback
  4. **Interact**: User interacts with visualization (click, drag, etc.)
  5. **Event**: Hook sends important events back via `pushEvent()`
  6. **Sync**: LiveView handles event and updates state if needed

  ## Minimal State Synchronization

  Follow these principles for optimal performance:

  - **Server State**: Only data, selections, and saved configurations
  - **Client State**: All visual state (positions, zoom, animations)
  - **Communication**: Throttle/debounce high-frequency events
  - **Updates**: Send only diffs or changed items when possible

  ## Helpers Available

  - `ensure_id/1` - Generates unique IDs
  - `encode_data/1` - JSON encodes data for JavaScript
  - `encode_config/1` - JSON encodes configuration
  - `merge_config/2` - Merges user config with defaults
  """

  @doc """
  Returns the default configuration for this component.
  Override this to provide component-specific defaults.
  """
  @callback default_config() :: map()

  @doc """
  Renders the component template.
  This is where you define your component's HTML/HEEx structure.
  """
  @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()

  @optional_callbacks [default_config: 0]

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component
      import D3Ex.Component

      @behaviour D3Ex.Component

      @doc """
      Renders the #{__MODULE__} component.
      """
      def component(assigns) do
        assigns =
          assigns
          |> ensure_id()
          |> merge_config(default_config())
          |> prepare_assigns()

        render(assigns)
      end

      @doc false
      def default_config, do: %{}

      @doc false
      def prepare_assigns(assigns), do: assigns

      defoverridable default_config: 0, prepare_assigns: 1
    end
  end

  @doc """
  Generates a unique DOM ID for a component if not provided.
  """
  def ensure_id(assigns) do
    Map.put_new_lazy(assigns, :id, fn ->
      "d3ex-#{:erlang.unique_integer([:positive])}"
    end)
  end

  @doc """
  Encodes data to JSON for passing to JavaScript hooks.
  """
  def encode_data(data) do
    Jason.encode!(data)
  end

  @doc """
  Encodes configuration to JSON for passing to JavaScript hooks.
  """
  def encode_config(config) do
    Jason.encode!(config)
  end

  @doc """
  Merges user-provided configuration with component defaults.
  """
  def merge_config(assigns, defaults) do
    user_config = Map.get(assigns, :config, %{})

    merged_config =
      defaults
      |> Map.merge(user_config)
      |> Map.merge(extract_config_from_assigns(assigns))

    Map.put(assigns, :config, merged_config)
  end

  # Extract configuration values from top-level assigns
  # This allows users to pass config as either:
  #   <.component config=%{width: 800} />
  # or:
  #   <.component width={800} />
  defp extract_config_from_assigns(assigns) do
    config_keys = [:width, :height, :margin, :color_scheme, :animation_duration]

    Enum.reduce(config_keys, %{}, fn key, acc ->
      case Map.get(assigns, key) do
        nil -> acc
        value -> Map.put(acc, key, value)
      end
    end)
  end

  @doc """
  Helper to build event handlers for D3 components.

  Returns a map of event names to event handler names that can be
  passed to JavaScript hooks.

  ## Example

      assigns = build_event_handlers(assigns, [:click, :hover, :drag_end])
      # Returns: %{on_click: "item_clicked", on_hover: "item_hovered", ...}
  """
  def build_event_handlers(assigns, event_names) do
    Enum.reduce(event_names, %{}, fn event, acc ->
      handler_key = :"on_#{event}"
      handler_value = Map.get(assigns, handler_key)

      if handler_value do
        Map.put(acc, handler_key, handler_value)
      else
        acc
      end
    end)
  end
end
