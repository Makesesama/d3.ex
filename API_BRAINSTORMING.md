# D3Ex Enhanced API Brainstorming

Exploring ergonomic API patterns inspired by VegaLite.ex and other successful Elixir libraries.

## What Makes VegaLite.ex Great?

```elixir
VegaLite.new(width: 400, height: 400)
|> VegaLite.data_from_values(data)
|> VegaLite.mark(:bar)
|> VegaLite.encode_field(:x, "category", type: :nominal)
|> VegaLite.encode_field(:y, "amount", type: :quantitative)
```

**Key Features:**
- ✅ Chainable/pipeable API
- ✅ Declarative (builds a spec, not imperative code)
- ✅ Progressive disclosure (start simple, add complexity)
- ✅ Type safety and validation
- ✅ Clear, domain-specific language

## The D3 vs VegaLite Difference

**VegaLite:** Declarative grammar → JSON spec → JavaScript renders
**D3:** Imperative API → Direct DOM manipulation

**Can we still create a beautiful API?** Absolutely! Here are options:

---

## Option 1: Chart Builder API (VegaLite-style)

### Concept
Build a configuration struct using chainable functions, then render.

### Example

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  import D3Ex

  def mount(_params, _session, socket) do
    chart =
      D3Ex.new(:network_graph, id: "my-graph")
      |> nodes(@nodes)
      |> links(@links)
      |> size(800, 600)
      |> force(:charge, strength: -300)
      |> force(:link, distance: 100)
      |> force(:collision, radius: 15)
      |> layout(:force_directed, center: true)
      |> interaction(:drag, enabled: true)
      |> interaction(:zoom, enabled: true, extent: [0.1, 10])
      |> on(:select, "node_selected")
      |> on(:drag_end, "position_saved")
      |> theme(:dark)
      |> animate(duration: 750)

    {:ok, assign(socket, :chart, chart)}
  end

  def render(assigns) do
    ~H"""
    <%= D3Ex.render(@chart) %>
    """
  end
end
```

### For Bar Charts

```elixir
chart =
  D3Ex.new(:bar_chart, id: "sales")
  |> data(@sales_data)
  |> encode(:x, field: :month, type: :nominal, label: "Month")
  |> encode(:y, field: :sales, type: :quantitative, label: "Sales ($)")
  |> encode(:color, field: :region, type: :nominal, scheme: :category10)
  |> size(600, 400)
  |> margins(top: 20, right: 20, bottom: 40, left: 60)
  |> on(:click, "bar_clicked")
  |> tooltip(fields: [:month, :sales, :region])

<%= D3Ex.render(chart) %>
```

### For Time Series

```elixir
chart =
  D3Ex.new(:line_chart, id: "metrics")
  |> data(@time_series)
  |> encode(:x, field: :timestamp, type: :temporal, label: "Time")
  |> encode(:y, field: :value, type: :quantitative, label: "Value")
  |> encode(:series, field: :metric, type: :nominal)
  |> curve(:monotone)
  |> points(show: true, radius: 4)
  |> area(show: true, opacity: 0.2)
  |> grid(show: true)
  |> legend(position: :right)
  |> on(:hover, "point_hovered")

<%= D3Ex.render(chart) %>
```

### Pros
- ✅ Familiar to VegaLite.ex users
- ✅ Very readable and declarative
- ✅ Easy to compose and reuse
- ✅ Can validate at build time
- ✅ Clear separation of concerns

### Cons
- ⚠️ Requires a new `D3Ex` module with builder functions
- ⚠️ More abstraction layer
- ⚠️ Need to map builder API to component props

### Implementation Strategy

```elixir
defmodule D3Ex do
  defstruct [
    :type,
    :id,
    :data,
    :encodings,
    :forces,
    :interactions,
    :events,
    :config
  ]

  def new(type, opts \\ []) do
    %__MODULE__{
      type: type,
      id: opts[:id] || generate_id(),
      encodings: %{},
      forces: %{},
      interactions: %{},
      events: %{},
      config: %{}
    }
  end

  def nodes(%__MODULE__{} = chart, nodes) do
    put_in(chart.data.nodes, nodes)
  end

  def force(%__MODULE__{} = chart, force_type, opts) do
    update_in(chart.forces, &Map.put(&1, force_type, opts))
  end

  # ... more builder functions
end
```

---

## Option 2: Declarative Schema/DSL

### Concept
Define charts as modules with a declarative schema (like Ecto schemas).

### Example

```elixir
defmodule MyApp.Charts.SalesOverview do
  use D3Ex.Chart

  chart :bar_chart do
    # Data binding
    data from: :assigns, key: :sales_data

    # Encodings
    axis :x do
      field :month
      type :ordinal
      label "Month"
    end

    axis :y do
      field :sales
      type :quantitative
      label "Sales ($)"
      scale domain: [0, :auto], nice: true
    end

    encoding :color do
      field :region
      scheme :category10
    end

    # Visual config
    style do
      width 600
      height 400
      margin top: 20, right: 20, bottom: 40, left: 60
      animation duration: 750, easing: :cubic
    end

    # Interactions
    interaction :hover, tooltip: true
    interaction :click, handler: "bar_clicked"

    # Responsive
    responsive breakpoints: [mobile: 320, tablet: 768, desktop: 1024]
  end
end

# Usage in LiveView
def render(assigns) do
  ~H"""
  <.chart module={MyApp.Charts.SalesOverview} assigns={assigns} />
  """
end
```

### Network Graph Schema

```elixir
defmodule MyApp.Charts.EntityGraph do
  use D3Ex.Chart

  chart :network_graph do
    data do
      nodes from: :assigns, key: :nodes
      links from: :assigns, key: :links
    end

    layout :force_directed do
      force :charge, strength: -300
      force :link, distance: 100, strength: 1
      force :collision, radius: 15
      force :center, strength: 0.1
    end

    style do
      width 1000
      height 600
      node_radius 10
      link_width fn link -> sqrt(link.value) end
      color_scheme :category10
    end

    interaction :drag, constrain: false
    interaction :zoom, extent: [0.1, 10]
    interaction :select, multi: false

    on :node_select, handler: "node_selected"
    on :node_drag_end, handler: "position_saved"

    state do
      selected from: :assigns, key: :selected_node
    end
  end
end
```

### Pros
- ✅ Very declarative and clean
- ✅ Reusable chart definitions
- ✅ Easy to share and version control
- ✅ Compile-time validation possible
- ✅ Great for teams (charts as modules)

### Cons
- ⚠️ Significant macro magic required
- ⚠️ Learning curve for the DSL
- ⚠️ Less flexible for one-off charts
- ⚠️ May feel "too much" for simple charts

---

## Option 3: Enhanced Component API with Helpers

### Concept
Keep current component API, but add helper functions for common patterns.

### Example

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  import D3Ex.Components.NetworkGraph
  import D3Ex.Helpers  # NEW: Helper functions

  def render(assigns) do
    ~H"""
    <.network_graph
      id="graph"
      nodes={@nodes}
      links={@links}

      forces={forces(
        charge: -300,
        link: [distance: 100, strength: 1],
        collision: 15,
        center: 0.1
      )}

      style={style(
        width: 800,
        height: 600,
        node_radius: 10,
        color_scheme: :category10
      )}

      interactions={interactions(
        drag: true,
        zoom: [enabled: true, extent: [0.1, 10]],
        select: [multi: false]
      )}

      on_select="node_selected"
      on_drag_end="position_saved"

      selected={@selected_node}
    />
    """
  end
end
```

### Bar Chart with Helpers

```elixir
<.bar_chart
  id="sales"
  data={@sales_data}

  encoding={encoding(
    x: [field: :month, type: :ordinal, label: "Month"],
    y: [field: :sales, type: :quantitative, label: "Sales"],
    color: [field: :region, scheme: :blues]
  )}

  style={style(
    width: 600,
    height: 400,
    margin: [top: 20, right: 20, bottom: 40, left: 60],
    animation_duration: 750
  )}

  tooltip={tooltip(fields: [:month, :sales, :region])}

  on_bar_click="bar_clicked"
/>
```

### Helper Module Implementation

```elixir
defmodule D3Ex.Helpers do
  @doc "Build force configuration for network graphs"
  def forces(opts) do
    %{
      charge: opts[:charge] || -300,
      link: normalize_force_opts(opts[:link], distance: 100),
      collision: normalize_force_opts(opts[:collision], radius: 15),
      center: opts[:center] || 0.1
    }
  end

  @doc "Build style configuration"
  def style(opts) do
    Map.new(opts)
  end

  @doc "Build encoding configuration"
  def encoding(opts) do
    Map.new(opts)
  end

  @doc "Build interaction configuration"
  def interactions(opts) do
    Map.new(opts)
  end

  @doc "Build tooltip configuration"
  def tooltip(opts) do
    %{
      enabled: true,
      fields: opts[:fields] || [],
      format: opts[:format] || :default
    }
  end

  # Preset themes
  def theme(:dark) do
    %{
      background: "#1a1a1a",
      text_color: "#ffffff",
      grid_color: "#333333",
      color_scheme: :schemeCategory10
    }
  end

  def theme(:light) do
    %{
      background: "#ffffff",
      text_color: "#000000",
      grid_color: "#e0e0e0",
      color_scheme: :schemeCategory10
    }
  end
end
```

### Pros
- ✅ Minimal changes to existing API
- ✅ Backward compatible
- ✅ Opt-in (can use or not use helpers)
- ✅ Easy to implement
- ✅ Reduces boilerplate for common patterns

### Cons
- ⚠️ Still somewhat verbose
- ⚠️ Not as elegant as full builder API
- ⚠️ Less discoverable than DSL

---

## Option 4: Data Transformation Pipeline

### Concept
Provide utilities for data transformation before visualization.

### Example

```elixir
defmodule MyAppWeb.AnalyticsLive do
  use MyAppWeb, :live_view
  import D3Ex.Data  # NEW: Data transformation helpers

  def prepare_chart_data(raw_data) do
    raw_data
    |> filter(fn row -> row.active end)
    |> group_by(:category)
    |> aggregate(:sum, :revenue)
    |> sort_by(:revenue, :desc)
    |> limit(10)
    |> add_percentage()
    |> add_rank()
  end

  def render(assigns) do
    ~H"""
    <.bar_chart
      id="top-categories"
      data={prepare_chart_data(@raw_data)}
      x={:category}
      y={:revenue}
      tooltip={[:category, :revenue, :percentage, :rank]}
    />
    """
  end
end
```

### Network Graph Data Prep

```elixir
# Transform relational data to graph structure
graph_data =
  @database_records
  |> D3Ex.Data.to_graph(
    node_from: :id,
    node_label: :name,
    link_from: :relationships,
    link_source: :from_id,
    link_target: :to_id
  )
  |> D3Ex.Data.filter_nodes(&(&1.importance > 5))
  |> D3Ex.Data.compute_centrality()
  |> D3Ex.Data.detect_communities()

<.network_graph
  id="graph"
  nodes={graph_data.nodes}
  links={graph_data.links}
/>
```

### Implementation

```elixir
defmodule D3Ex.Data do
  @doc "Filter data"
  def filter(data, fun) when is_function(fun) do
    Enum.filter(data, fun)
  end

  @doc "Group by field"
  def group_by(data, field) do
    Enum.group_by(data, & &1[field])
  end

  @doc "Aggregate grouped data"
  def aggregate(grouped_data, operation, field) do
    Map.new(grouped_data, fn {key, records} ->
      value =
        case operation do
          :sum -> Enum.sum(Enum.map(records, & &1[field]))
          :avg -> Enum.sum(Enum.map(records, & &1[field])) / length(records)
          :count -> length(records)
          :min -> Enum.min_by(records, & &1[field]) |> Map.get(field)
          :max -> Enum.max_by(records, & &1[field]) |> Map.get(field)
        end

      {key, %{field => key, :"#{operation}_#{field}" => value}}
    end)
    |> Map.values()
  end

  @doc "Convert relational data to graph structure"
  def to_graph(data, opts) do
    # Implementation
  end

  @doc "Compute graph metrics"
  def compute_centrality(graph) do
    # Implementation using graph algorithms
  end
end
```

### Pros
- ✅ Solves real pain point (data prep)
- ✅ Can be used independently
- ✅ Complements any API choice
- ✅ Useful for all chart types

### Cons
- ⚠️ Requires graph algorithm implementations
- ⚠️ May overlap with Enum/Stream

---

## Option 5: Preset Chart Library

### Concept
Pre-built, opinionated chart configurations for common use cases.

### Example

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  import D3Ex.Presets  # NEW: Preset charts

  def render(assigns) do
    ~H"""
    <!-- Pre-configured charts that "just work" -->

    <.sales_chart
      id="monthly-sales"
      data={@sales}
      x={:month}
      y={:amount}
      group={:region}
    />

    <.real_time_metrics
      id="metrics"
      data={@metrics}
      time={:timestamp}
      metrics={[:cpu, :memory, :disk]}
      window={:last_hour}
    />

    <.entity_relationship_graph
      id="entities"
      nodes={@entities}
      links={@relationships}
      on_select="entity_selected"
    />

    <.comparison_bars
      id="regions"
      data={@regional_data}
      category={:region}
      values={[:q1, :q2, :q3, :q4]}
    />

    <.geographic_choropleth
      id="map"
      geo_data={@us_states}
      value={:population}
      color_scale={:blues}
    />
    """
  end
end
```

### Preset with Customization

```elixir
<.sales_chart
  id="sales"
  data={@sales}
  x={:month}
  y={:amount}

  {# Override defaults #}
  theme={:dark}
  height={800}
  show_trend_line={true}
  annotations={[
    %{x: "March", label: "Product Launch", color: :red}
  ]}
/>
```

### Pros
- ✅ Fastest time to value
- ✅ Consistent design across app
- ✅ Best practices built-in
- ✅ Can still customize
- ✅ Great for common use cases

### Cons
- ⚠️ Less flexible
- ⚠️ Can become bloated
- ⚠️ Opinionated

---

## Option 6: Multi-Chart Composition

### Concept
Compose multiple charts into dashboards declaratively.

### Example

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  import D3Ex.Dashboard  # NEW: Dashboard composition

  def mount(_params, _session, socket) do
    dashboard =
      D3Ex.Dashboard.new()
      |> layout(:grid, columns: 2)
      |> add_chart(:sales_chart,
        type: :bar_chart,
        data: @sales,
        position: {0, 0}
      )
      |> add_chart(:metrics_chart,
        type: :line_chart,
        data: @metrics,
        position: {1, 0}
      )
      |> add_chart(:network_chart,
        type: :network_graph,
        nodes: @nodes,
        links: @links,
        position: {0, 1},
        span: {2, 1}  # Span 2 columns
      )
      |> link_selection([:sales_chart, :network_chart])  # Coordinated selection
      |> theme(:corporate)

    {:ok, assign(socket, :dashboard, dashboard)}
  end

  def render(assigns) do
    ~H"""
    <%= D3Ex.Dashboard.render(@dashboard) %>
    """
  end
end
```

### Pros
- ✅ Multi-chart coordination
- ✅ Consistent layouts
- ✅ Linked selections
- ✅ Great for dashboards

### Cons
- ⚠️ Complex to implement
- ⚠️ May be too specific
- ⚠️ Layout challenges

---

## Recommendations: What Should We Build?

### Phase 1: Quick Wins (High Value, Low Effort)

1. **Option 3: Helper Functions** ✅
   - Add `D3Ex.Helpers` module
   - Functions: `forces/1`, `style/1`, `interactions/1`, `theme/1`
   - Reduces boilerplate immediately
   - Fully backward compatible

2. **Option 4: Data Transformation** ✅
   - Add `D3Ex.Data` module
   - Functions: `filter/2`, `group_by/2`, `aggregate/3`, `to_graph/2`
   - Solves real pain point
   - Works with any API

### Phase 2: Major Enhancement (High Value, Medium Effort)

3. **Option 1: Builder API** ✅✅✅
   - Add `D3Ex` builder module
   - Chainable functions like VegaLite.ex
   - Most requested by community
   - Biggest UX improvement

### Phase 3: Advanced Features (Medium Value, High Effort)

4. **Option 5: Preset Charts** ✅
   - Add `D3Ex.Presets` module
   - 5-10 common chart types
   - Speed up common use cases

### Phase 4: Expert Features (Nice to Have)

5. **Option 2: DSL** (maybe)
   - For teams that want chart-as-modules
   - Overkill for most users

6. **Option 6: Dashboard** (maybe)
   - If there's demand
   - Separate package?

---

## Example: What Phase 1 Would Look Like

```elixir
# Current API (still works!)
<.network_graph
  id="graph"
  nodes={@nodes}
  links={@links}
  charge_strength={-300}
  link_distance={100}
/>

# NEW: With helpers (less boilerplate)
<.network_graph
  id="graph"
  nodes={@nodes}
  links={@links}
  forces={forces(charge: -300, link: [distance: 100])}
  style={theme(:dark)}
/>

# NEW: With data prep
<.bar_chart
  id="top-10"
  data={
    @raw_sales
    |> D3Ex.Data.filter(&(&1.active))
    |> D3Ex.Data.group_by(:region)
    |> D3Ex.Data.aggregate(:sum, :amount)
    |> D3Ex.Data.limit(10)
  }
  x={:region}
  y={:sum_amount}
/>
```

---

## Questions for You

1. **Which option excites you most?**
   - Builder API (Option 1)?
   - Helper functions (Option 3)?
   - Data transformation (Option 4)?
   - Presets (Option 5)?

2. **What's your main pain point with current approach?**
   - Too verbose?
   - Hard to configure complex charts?
   - Data preparation?
   - Lack of presets?

3. **What's your priority?**
   - Speed of implementation?
   - Elegance of API?
   - Flexibility?
   - Ease of learning?

4. **Should we focus on**:
   - Making simple things simple? (Presets)
   - Making complex things possible? (Builder)
   - Making common things convenient? (Helpers)

Let me know your thoughts and we can implement the best approach!
