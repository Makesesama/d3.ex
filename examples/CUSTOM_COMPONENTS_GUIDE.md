# Building Custom D3 Components with D3Ex

This guide walks you through creating custom D3 visualizations that integrate seamlessly with Phoenix LiveView.

## The D3Ex Component Pattern

D3Ex uses a three-part pattern for components:

1. **Elixir Module** - Defines the component API and renders the container
2. **JavaScript Hook** - Initializes and updates the D3 visualization
3. **D3.js Code** - The actual visualization logic

## Step-by-Step: Building a Sunburst Chart

Let's build a hierarchical sunburst chart from scratch.

### Step 1: Create the Elixir Component

Create `lib/my_app/d3_components/sunburst_chart.ex`:

```elixir
defmodule MyApp.D3Components.SunburstChart do
  @moduledoc """
  Hierarchical sunburst chart for visualizing tree structures.
  """

  use D3Ex.Component

  @impl true
  def default_config do
    %{
      width: 600,
      height: 600,
      radius: 250,
      color_scheme: "schemeCategory10",
      animation_duration: 750
    }
  end

  @impl true
  def prepare_assigns(assigns) do
    assigns
    |> Map.put_new(:data, %{})
    |> Map.put_new(:on_segment_click, nil)
    |> Map.put_new(:on_segment_hover, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="D3SunburstChart"
      data-items={encode_data(@data)}
      data-config={encode_config(@config)}
      phx-update="ignore"
      class="d3-sunburst-chart"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>

      <%= if @on_segment_click do %>
        <input type="hidden" name="on_segment_click" value={@on_segment_click} />
      <% end %>
    </div>
    """
  end
end
```

### Step 2: Create the JavaScript Hook

Create `assets/js/hooks/sunburst_chart.js`:

```javascript
import { D3Hook } from "../../deps/d3_ex/priv/static/js/d3_hooks.js";

export const D3SunburstChart = {
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
    const { width, height, radius } = this.config;

    // Setup SVG
    this.svg = d3.select(this.el).select('svg');
    this.g = this.svg.append('g')
      .attr('transform', `translate(${width/2}, ${height/2})`);

    // Create partition layout
    this.partition = d3.partition()
      .size([2 * Math.PI, radius]);

    // Create arc generator
    this.arc = d3.arc()
      .startAngle(d => d.x0)
      .endAngle(d => d.x1)
      .innerRadius(d => d.y0)
      .outerRadius(d => d.y1);

    // Color scale
    this.color = d3.scaleOrdinal(d3.schemeCategory10);

    this.renderChart();
  },

  renderChart() {
    const d3 = window.d3;

    // Convert data to hierarchy
    const root = d3.hierarchy(this.data)
      .sum(d => d.value || 0)
      .sort((a, b) => b.value - a.value);

    // Compute partition layout
    this.partition(root);

    // Render segments
    const segments = this.g.selectAll('.segment')
      .data(root.descendants())
      .join('path')
      .attr('class', 'segment')
      .attr('d', this.arc)
      .style('fill', d => this.color(d.depth))
      .style('stroke', '#fff')
      .style('stroke-width', 2)
      .on('click', (event, d) => {
        event.stopPropagation();
        this.sendEvent('on_segment_click', {
          name: d.data.name,
          value: d.value,
          depth: d.depth
        });
      })
      .on('mouseover', function(event, d) {
        d3.select(this)
          .transition()
          .duration(200)
          .style('opacity', 0.8);
      })
      .on('mouseout', function(event, d) {
        d3.select(this)
          .transition()
          .duration(200)
          .style('opacity', 1);
      });

    // Add labels
    this.g.selectAll('.label')
      .data(root.descendants().filter(d => d.depth > 0))
      .join('text')
      .attr('class', 'label')
      .attr('transform', d => {
        const angle = (d.x0 + d.x1) / 2;
        const radius = (d.y0 + d.y1) / 2;
        return `
          rotate(${angle * 180 / Math.PI - 90})
          translate(${radius},0)
          rotate(${angle > Math.PI ? 180 : 0})
        `;
      })
      .attr('text-anchor', 'middle')
      .text(d => d.data.name)
      .style('font-size', '10px')
      .style('pointer-events', 'none');
  },

  updateChart() {
    // Clear existing visualization
    this.g.selectAll('*').remove();
    this.renderChart();
  }
};
```

### Step 3: Register the Hook

In `assets/js/app.js`:

```javascript
import { D3SunburstChart } from "./hooks/sunburst_chart.js";

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    D3SunburstChart,
    // ... other hooks
  }
});
```

### Step 4: Use Your Component

```elixir
defmodule MyAppWeb.HierarchyLive do
  use MyAppWeb, :live_view
  import MyApp.D3Components.SunburstChart

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :hierarchy_data, sample_data())}
  end

  def handle_event("segment_clicked", payload, socket) do
    IO.inspect(payload, label: "Segment clicked")
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.sunburst_chart
      id="hierarchy"
      data={@hierarchy_data}
      on_segment_click="segment_clicked"
      width={800}
      height={800}
    />
    """
  end

  defp sample_data do
    %{
      name: "Root",
      children: [
        %{
          name: "A",
          children: [
            %{name: "A1", value: 100},
            %{name: "A2", value: 150}
          ]
        },
        %{
          name: "B",
          children: [
            %{name: "B1", value: 200},
            %{name: "B2", value: 80}
          ]
        }
      ]
    }
  end
end
```

## Advanced Patterns

### Pattern 1: Streaming Data Updates

For real-time visualizations:

```elixir
# LiveView
def mount(_params, _session, socket) do
  if connected?(socket) do
    :timer.send_interval(1000, self(), :tick)
  end
  {:ok, assign(socket, :data, [])}
end

def handle_info(:tick, socket) do
  new_point = %{x: :os.system_time(:millisecond), y: :rand.uniform(100)}

  # Send incremental update instead of full data
  {:noreply, push_event(socket, "chart:add_point", %{point: new_point})}
end
```

```javascript
// Hook
this.handleEvent('chart:add_point', ({ point }) => {
  this.data.push(point);

  // Keep only last 50 points
  if (this.data.length > 50) {
    this.data.shift();
  }

  this.updateChart();
});
```

### Pattern 2: Complex Interactions with State Management

```elixir
def handle_event("brush_selected", %{"selection" => ids}, socket) do
  # Update multiple states based on complex interaction
  {:noreply,
    socket
    |> assign(:selected_items, ids)
    |> assign(:filtered_data, filter_by_ids(socket.assigns.data, ids))
    |> push_event("highlight:update", %{ids: ids})}
end
```

### Pattern 3: Efficient Large Dataset Handling

```javascript
// Use Canvas instead of SVG for large datasets
initChart() {
  this.canvas = this.el.querySelector('canvas');
  this.ctx = this.canvas.getContext('2d');

  // Use virtual scrolling/windowing
  this.visibleRange = { start: 0, end: 1000 };

  this.renderChart();
}

renderChart() {
  const visibleData = this.data.slice(
    this.visibleRange.start,
    this.visibleRange.end
  );

  // Render only visible data
  visibleData.forEach(d => {
    this.ctx.beginPath();
    // ... drawing code
  });
}
```

## Component Design Checklist

When building a custom component, ensure:

- [ ] **Minimal State Sync**: Only essential data goes through LiveView
- [ ] **Event Throttling**: High-frequency events (drag, pan) are throttled
- [ ] **Incremental Updates**: Support both full replace and incremental updates
- [ ] **Proper Cleanup**: Remove event listeners and D3 elements in `destroyed()`
- [ ] **Configuration**: Expose sensible defaults with override options
- [ ] **Documentation**: Document data format, events, and configuration
- [ ] **Accessibility**: Add ARIA labels and keyboard navigation where appropriate
- [ ] **Performance**: Test with realistic data sizes

## Common Gotchas

### 1. Missing `phx-update="ignore"`

Always add `phx-update="ignore"` to your component container:

```heex
<div phx-update="ignore" phx-hook="MyD3Hook">
  <!-- D3 owns this DOM -->
</div>
```

Without this, LiveView will attempt to patch the D3-generated DOM, causing conflicts.

### 2. Not Using `getConfig()` Helper

Always use the helper methods from `D3Hook`:

```javascript
// ✅ Good
this.config = this.getConfig();

// ❌ Bad - manual parsing
this.config = JSON.parse(this.el.dataset.config);
```

### 3. Forgetting to Check for D3

Always check if D3 is loaded:

```javascript
mounted() {
  if (!window.d3) {
    console.error('D3.js is not loaded');
    return;
  }
  // ... rest of code
}
```

### 4. Pushing Events Without Handlers

Check if event handler exists before pushing:

```javascript
// Use the helper
this.sendEvent('on_click', data);

// Or check manually
const handler = this.getEventHandler('on_click');
if (handler) {
  this.pushEvent(handler, data);
}
```

## Example Gallery

More examples available in the `examples/` directory:

- **Chord Diagram** - Relationship matrix visualization
- **Tree Map** - Hierarchical space-filling layout
- **Sankey Diagram** - Flow diagram with nodes and links
- **Geographic Maps** - Choropleth maps with TopoJSON
- **Real-time Dashboard** - Multiple synchronized charts

## Resources

- [D3.js Gallery](https://observablehq.com/@d3/gallery)
- [D3.js API Reference](https://github.com/d3/d3/blob/main/API.md)
- [Phoenix LiveView Hooks Guide](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)

## Getting Help

If you build a custom component and need help:

1. Check existing component implementations for patterns
2. Review the `D3Hook` base class for available utilities
3. Join the discussion on GitHub
4. Share your component with the community!
