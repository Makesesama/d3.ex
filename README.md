# D3Ex

**D3Ex** provides seamless integration between D3.js and Phoenix LiveView using minimal state synchronization for high-performance, interactive visualizations.

## Philosophy: Minimal State Synchronization

D3Ex implements a "thin server, rich client" architecture that maximizes performance:

- **Server (Elixir/LiveView)**: Manages data state, selections, and business logic
- **Client (D3.js)**: Owns visual state, animations, and high-frequency interactions
- **Communication**: Only essential state changes flow between server and client

This approach delivers:
- ⚡ **High Performance**: Minimal WebSocket traffic, no DOM diffing for visualizations
- 🎯 **Responsive UI**: D3.js handles interactions at 60fps
- 📈 **Scalable**: Server focuses on data, not visual pixels
- 🔄 **Real-time**: LiveView provides instant data sync across clients

## Installation

Add `d3_ex` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:d3_ex, "~> 0.1.0"}
  ]
end
```

Run `mix deps.get` to install.

## Setup

### 1. Include D3.js

Add D3.js to your `assets/js/app.js` or include it via CDN in your layout:

```html
<!-- In your layout template -->
<script src="https://d3js.org/d3.v7.min.js"></script>
```

Or install via npm:

```bash
cd assets && npm install d3
```

### 2. Import D3Ex Hooks

In your `assets/js/app.js`:

```javascript
import { D3NetworkGraph, D3BarChart, D3LineChart } from "../../deps/d3_ex/priv/static/js/d3_hooks.js";

// Or if you copied the hooks to your assets:
// import { D3NetworkGraph, D3BarChart, D3LineChart } from "./hooks/d3_hooks.js";

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {
    D3NetworkGraph,
    D3BarChart,
    D3LineChart
  }
});
```

### 3. Import Components in LiveView

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  # Import the components you need
  import D3Ex.Components.NetworkGraph
  import D3Ex.Components.BarChart
  import D3Ex.Components.LineChart
end
```

## Quick Start

### Ergonomic API with Helpers (NEW!)

D3Ex provides helper modules inspired by VegaLite.ex for data transformation and configuration:

```elixir
# Transform data with pipeline
chart_data =
  raw_sales
  |> D3Ex.Data.filter(&(&1.active))
  |> D3Ex.Data.group_by(:category)
  |> D3Ex.Data.aggregate(:sum, :revenue)
  |> D3Ex.Data.sort_by(:revenue, :desc)
  |> D3Ex.Data.limit(10)

# Build configuration with helpers
config =
  D3Ex.Config.network_graph(
    size: {1000, 800},
    forces: [charge: -400, link: [distance: 150]],
    theme: :dark,
    interactions: [drag: true, zoom: true]
  )

# Use in component
<.bar_chart
  id="top-sales"
  data={chart_data}
  x_key={:category}
  y_key={:sum_revenue}
  config={config}
/>
```

See [Using Helpers Example](examples/using_helpers_live.ex) for complete examples.

### Network Graph

```elixir
defmodule MyAppWeb.GraphLive do
  use MyAppWeb, :live_view
  import D3Ex.Components.NetworkGraph

  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      nodes: [
        %{id: "1", label: "Alice", group: "A"},
        %{id: "2", label: "Bob", group: "B"},
        %{id: "3", label: "Charlie", group: "A"}
      ],
      links: [
        %{source: "1", target: "2"},
        %{source: "2", target: "3"}
      ],
      selected_node: nil
    )}
  end

  def handle_event("node_selected", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_node: id)}
  end

  def render(assigns) do
    ~H"""
    <.network_graph
      id="my-graph"
      nodes={@nodes}
      links={@links}
      selected={@selected_node}
      on_select="node_selected"
      width={800}
      height={600}
    />
    """
  end
end
```

### Bar Chart

```elixir
def render(assigns) do
  ~H"""
  <.bar_chart
    id="sales-chart"
    data={[
      %{month: "Jan", sales: 1000},
      %{month: "Feb", sales: 1500},
      %{month: "Mar", sales: 1200}
    ]}
    x_key={:month}
    y_key={:sales}
    on_bar_click="bar_clicked"
    width={600}
    height={400}
  />
  """
end
```

### Line Chart

```elixir
def render(assigns) do
  ~H"""
  <.line_chart
    id="trends-chart"
    data={@time_series_data}
    x_key={:date}
    y_key={:value}
    series_key={:metric}
    on_point_click="point_clicked"
    width={800}
    height={400}
  />
  """
end
```

## Built-in Components

### Network Graph

Force-directed network graph with draggable nodes, zoom, and pan.

**Options:**
- `nodes` - List of node maps with `:id` field (required)
- `links` - List of link maps with `:source` and `:target` fields (required)
- `selected` - ID of currently selected node
- `on_select` - Event handler for node clicks
- `on_position_save` - Event handler for drag end (receives final position)
- `width`, `height` - Canvas dimensions
- `charge_strength` - Force strength for node repulsion (default: -300)
- `link_distance` - Target distance between linked nodes (default: 100)
- `enable_zoom`, `enable_drag` - Enable interactions (default: true)

### Bar Chart

Animated bar chart with click interactions.

**Options:**
- `data` - List of data maps (required)
- `x_key`, `y_key` - Keys for x and y values (required)
- `color_key` - Key for grouping/coloring bars
- `on_bar_click`, `on_bar_hover` - Event handlers
- `animation_duration` - Animation duration in ms (default: 750)
- `bar_padding` - Padding between bars (default: 0.1)

### Line Chart

Multi-line chart with tooltips and interactive points.

**Options:**
- `data` - List of data maps (required)
- `x_key`, `y_key` - Keys for x and y values (required)
- `series_key` - Key for grouping multiple lines
- `curve_type` - "linear", "monotone", or "step" (default: "monotone")
- `show_points` - Show data points (default: true)
- `show_area` - Fill area under lines (default: false)
- `show_grid` - Show grid lines (default: true)

## Building Custom Components

D3Ex is designed to be extensible. You can create any D3 visualization by following this pattern:

### 1. Create an Elixir Component Module

```elixir
defmodule MyApp.D3Components.PieChart do
  use D3Ex.Component

  @impl true
  def default_config do
    %{
      width: 500,
      height: 500,
      inner_radius: 0,
      outer_radius: 200,
      color_scheme: "schemeCategory10"
    }
  end

  @impl true
  def prepare_assigns(assigns) do
    assigns
    |> Map.put_new(:data, [])
    |> Map.put_new(:value_key, :value)
    |> Map.put_new(:label_key, :label)
    |> Map.put_new(:on_slice_click, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="D3PieChart"
      data-items={encode_data(@data)}
      data-config={encode_config(@config)}
      phx-update="ignore"
      class="d3-pie-chart"
    >
      <svg width={@config.width} height={@config.height}></svg>

      <%= if @on_slice_click do %>
        <input type="hidden" name="on_slice_click" value={@on_slice_click} />
      <% end %>
    </div>
    """
  end
end
```

### 2. Create a JavaScript Hook

Create `assets/js/hooks/pie_chart.js`:

```javascript
import { D3Hook } from "../../deps/d3_ex/priv/static/js/d3_hooks.js";

export const D3PieChart = {
  mounted() {
    if (!window.d3) {
      console.error('D3.js is not loaded');
      return;
    }

    this.config = this.getConfig();
    this.data = this.getData();
    this.initChart();
  },

  updated() {
    this.data = this.getData();
    this.updateChart();
  },

  destroyed() {
    this.cleanup();
  },

  // Inherit helper methods from D3Hook
  ...D3Hook.prototype,

  initChart() {
    const d3 = window.d3;
    const { width, height, inner_radius, outer_radius } = this.config;

    this.svg = d3.select(this.el).select('svg');
    this.g = this.svg.append('g')
      .attr('transform', `translate(${width/2}, ${height/2})`);

    // Create pie layout
    this.pie = d3.pie().value(d => d.value);

    // Create arc generator
    this.arc = d3.arc()
      .innerRadius(inner_radius)
      .outerRadius(outer_radius);

    // Create color scale
    this.color = d3.scaleOrdinal(d3.schemeCategory10);

    this.renderChart();
  },

  renderChart() {
    const d3 = window.d3;

    // Bind data
    const arcs = this.g.selectAll('.arc')
      .data(this.pie(this.data));

    // Enter + Update
    const arcEnter = arcs.enter()
      .append('g')
      .attr('class', 'arc');

    arcEnter.append('path')
      .attr('fill', (d, i) => this.color(i))
      .on('click', (event, d) => {
        this.sendEvent('on_slice_click', d.data);
      });

    arcEnter.merge(arcs).select('path')
      .transition()
      .duration(750)
      .attr('d', this.arc);

    // Exit
    arcs.exit().remove();
  },

  updateChart() {
    this.renderChart();
  }
};
```

### 3. Register the Hook

In `assets/js/app.js`:

```javascript
import { D3PieChart } from "./hooks/pie_chart.js";

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    D3PieChart,
    // ... other hooks
  }
});
```

### 4. Use Your Custom Component

```elixir
import MyApp.D3Components.PieChart

def render(assigns) do
  ~H"""
  <.component
    id="my-pie"
    data={@pie_data}
    on_slice_click="slice_clicked"
  />
  """
end
```

## Performance Best Practices

### 1. Minimal State Synchronization

Only sync essential state between server and client:

```elixir
# ✅ Good: Minimal server state
assign(socket,
  nodes: @nodes,              # data
  selected_node_id: @selected # selection
)

# ❌ Bad: Don't sync visual state
assign(socket,
  node_positions: %{...},     # D3 manages this
  zoom_level: 1.5,            # D3 manages this
  drag_state: :dragging       # D3 manages this
)
```

### 2. Throttle/Debounce High-Frequency Events

```javascript
// In your hook, throttle position updates
d3.drag()
  .on('end', (event, d) => {
    // Only send final position after drag completes
    this.sendEvent('on_position_save', {
      id: d.id,
      x: d.x,
      y: d.y
    }, 500); // 500ms throttle
  });
```

### 3. Use Incremental Updates

Instead of replacing all data:

```elixir
# ✅ Good: Send only what changed
push_event(socket, "graph:add_node", %{
  node: %{id: "new", label: "New Node"}
})

# ❌ Bad: Replace entire dataset
assign(socket, nodes: all_nodes_including_new_one)
```

### 4. Use `phx-update="ignore"` for D3 Containers

```heex
<div phx-update="ignore" phx-hook="D3Chart">
  <!-- D3 owns this DOM, LiveView won't touch it -->
</div>
```

## Advanced Patterns

### Real-time Multi-User Graphs

```elixir
defmodule MyAppWeb.CollaborativeGraphLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MyApp.PubSub, "graph_updates")
    end

    {:ok, load_graph(socket)}
  end

  def handle_info({:node_added, node}, socket) do
    # Push incremental update to client
    {:noreply, push_event(socket, "graph:add_node", %{node: node})}
  end

  def handle_event("node_selected", %{"id" => id}, socket) do
    # Broadcast to other users
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "graph_updates",
      {:node_selected, id, socket.assigns.user_id}
    )

    {:noreply, assign(socket, selected: id)}
  end
end
```

### Custom Force Simulations

```javascript
// In your custom hook
this.simulation = d3.forceSimulation(nodes)
  .force('link', d3.forceLink(links).id(d => d.id))
  .force('charge', d3.forceManyBody().strength(-500))
  .force('center', d3.forceCenter(width/2, height/2))
  .force('collision', d3.forceCollide().radius(20))
  // Add custom forces
  .force('x', d3.forceX(width/2).strength(0.1))
  .force('y', d3.forceY(height/2).strength(0.1));
```

### Handling Large Datasets

```elixir
# Server-side pagination
def handle_event("load_more_nodes", _params, socket) do
  new_nodes = load_next_page(socket.assigns.page + 1)

  {:noreply,
    socket
    |> update(:nodes, &(&1 ++ new_nodes))
    |> update(:page, &(&1 + 1))
    |> push_event("graph:add_nodes", %{nodes: new_nodes})}
end
```

## Examples

Check out the `examples/` directory for complete working examples:

- `examples/network_graph_live.ex` - Interactive network visualization
- `examples/dashboard_live.ex` - Multiple charts with real-time updates
- `examples/custom_viz_live.ex` - Building custom D3 components

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Phoenix LiveView                      │
│  ┌────────────────────────────────────────────────────┐ │
│  │  State: @nodes, @links, @selected                  │ │
│  │  Events: node_selected, position_saved             │ │
│  └────────────────────────────────────────────────────┘ │
└───────────────────┬─────────────────────┬───────────────┘
                    │ push_event          │ pushEvent
                    │ (data updates)      │ (user actions)
                    ▼                     ▲
┌─────────────────────────────────────────────────────────┐
│                   LiveView Hook (JS)                     │
│  ┌────────────────────────────────────────────────────┐ │
│  │  mounted() → initialize D3                         │ │
│  │  updated() → update with new data                  │ │
│  │  Event handlers → pushEvent to server              │ │
│  └────────────────────────────────────────────────────┘ │
└───────────────────┬─────────────────────────────────────┘
                    │ D3 API calls
                    ▼
┌─────────────────────────────────────────────────────────┐
│                      D3.js                               │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Visual State: positions, zoom, animations         │ │
│  │  Force Simulation: layout computation              │ │
│  │  DOM Manipulation: rendering, transitions          │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Resources

- [Phoenix LiveView Docs](https://hexdocs.pm/phoenix_live_view/)
- [D3.js Documentation](https://d3js.org/)
- [Example Applications](https://github.com/Makesesama/d3.ex/tree/main/examples)

## Credits

Built with ❤️ by the Elixir community.

Special thanks to the creators of Phoenix LiveView and D3.js for making this integration possible.
