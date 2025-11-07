# D3Ex Enhanced API - Implementation Plan

Following the VegaLite.ex pattern: **Abstract data and events, let JavaScript handle rendering.**

## ✅ The Right Approach (Following Gemini Guidance)

**Elixir Side (Data & Events):**
- Define data structures (nodes, links, data points)
- Configure visualization options
- Handle server-side events
- Allow custom D3 code injection

**JavaScript Side (Rendering):**
- Accept JSON configuration
- Execute D3 rendering
- Handle high-frequency interactions
- Call back to server for important events

---

## Implementation: Three Enhancements

### 1. Data Model Helpers (`D3Ex.Data`)

Make it easy to transform and prepare data for visualizations.

```elixir
# Transform database records to graph structure
graph_data =
  MyApp.get_users_and_relationships()
  |> D3Ex.Data.to_graph(
    node_key: :id,
    node_label: :name,
    link_from: :follows,
    link_source: :follower_id,
    link_target: :following_id
  )

# Prepare bar chart data
chart_data =
  raw_sales
  |> D3Ex.Data.filter(&(&1.active))
  |> D3Ex.Data.group_by(:category)
  |> D3Ex.Data.aggregate(:sum, :revenue)
  |> D3Ex.Data.sort_by(:revenue, :desc)
  |> D3Ex.Data.limit(10)
```

### 2. Configuration Helpers (`D3Ex.Config`)

Simplify common configuration patterns.

```elixir
<.network_graph
  id="graph"
  nodes={@nodes}
  links={@links}

  # Use helper to build force config
  config={
    D3Ex.Config.forces(
      charge: -300,
      link: [distance: 100, strength: 1],
      collision: 15,
      center: 0.1
    )
    |> D3Ex.Config.merge(D3Ex.Config.theme(:dark))
    |> D3Ex.Config.merge(%{
      width: 800,
      height: 600
    })
  }
/>
```

### 3. Custom D3 Code Injection

Allow advanced users to inject custom D3 code for specific behaviors.

```elixir
<.network_graph
  id="graph"
  nodes={@nodes}
  links={@links}

  # Inject custom D3 code for node styling
  custom_node_attr={fn ->
    """
    .attr('r', d => d.importance * 5)
    .attr('fill', d => d.temperature > 50 ? 'red' : 'blue')
    .style('stroke-width', d => d.selected ? 3 : 1)
    """
  end}

  # Inject custom behavior on node creation
  on_node_enter={fn ->
    """
    .call(d3.drag()
      .on('start', function(event, d) {
        // Custom drag behavior
        d3.select(this).raise().attr('stroke', 'black');
      })
    )
    .on('dblclick', function(event, d) {
      // Custom double-click
      alert('Double clicked: ' + d.label);
    })
    """
  end}
/>
```

---

## Component API Design

### Current (Good Foundation)

```elixir
<.network_graph
  id="graph"
  nodes={@nodes}
  links={@links}
  on_select="node_selected"
  width={800}
  height={600}
  charge_strength={-300}
/>
```

### Enhanced (With Helpers)

```elixir
<.network_graph
  id="graph"

  {# Data (transformed) #}
  data={D3Ex.Data.to_graph(@db_records, ...)}

  {# Config (simplified) #}
  config={D3Ex.Config.network_graph(
    forces: [charge: -300, link: [distance: 100]],
    theme: :dark,
    size: {800, 600}
  )}

  {# Events #}
  on_select="node_selected"
  on_drag_end="position_saved"

  {# Custom behavior (optional) #}
  custom_node_style={&custom_node_styling/0}
/>
```

### Advanced (With Code Injection)

```elixir
<.network_graph
  id="advanced-graph"
  nodes={@nodes}
  links={@links}

  {# Full config object #}
  config={%{
    width: 1000,
    height: 800,
    forces: %{charge: -500, link: %{distance: 150}},

    # Inject custom D3 code
    custom_d3: %{
      node_init: """
        .attr('r', d => Math.sqrt(d.value) * 2)
        .style('fill', d => colorScale(d.group))
        .on('mouseover', function(event, d) {
          tooltip.show(d);
          d3.select(this).transition().attr('r', d => Math.sqrt(d.value) * 3);
        })
        .on('mouseout', function(event, d) {
          tooltip.hide();
          d3.select(this).transition().attr('r', d => Math.sqrt(d.value) * 2);
        })
      """,

      link_init: """
        .style('stroke', d => d.type === 'strong' ? '#000' : '#999')
        .style('stroke-width', d => d.weight * 2)
      """,

      on_tick: """
        // Custom tick behavior
        node.attr('cx', d => Math.max(20, Math.min(width - 20, d.x)))
            .attr('cy', d => Math.max(20, Math.min(height - 20, d.y)));
      """
    }
  }}
/>
```

---

## Implementation Priority

### ✅ Phase 1: Data Helpers (Week 1)
**Goal:** Make data transformation easy

Files to create:
- `lib/d3_ex/data.ex` - Data transformation utilities

Functions:
- `to_graph/2` - Convert relational data to graph structure
- `filter/2` - Filter data
- `group_by/2` - Group data by field
- `aggregate/3` - Aggregate grouped data
- `sort_by/3` - Sort data
- `limit/2` - Limit results
- `add_field/3` - Add computed field

### ✅ Phase 2: Config Helpers (Week 1)
**Goal:** Simplify configuration

Files to create:
- `lib/d3_ex/config.ex` - Configuration builders

Functions:
- `forces/1` - Build force configuration
- `theme/1` - Preset themes (dark, light, corporate, etc.)
- `network_graph/1` - Network graph config builder
- `bar_chart/1` - Bar chart config builder
- `line_chart/1` - Line chart config builder
- `merge/2` - Merge configurations

### ✅ Phase 3: Code Injection (Week 2)
**Goal:** Allow custom D3 code for advanced users

Updates needed:
- Update components to accept `custom_d3` option
- Update JavaScript hooks to execute custom code
- Add safety guards and validation
- Document injection points

---

## Data Helpers Implementation Example

```elixir
defmodule D3Ex.Data do
  @moduledoc """
  Data transformation utilities for D3 visualizations.

  Helps transform raw data into formats suitable for D3 components.
  """

  @doc """
  Convert relational data to graph structure.

  ## Example

      users = [
        %{id: 1, name: "Alice", department: "Engineering"},
        %{id: 2, name: "Bob", department: "Sales"}
      ]

      relationships = [
        %{from: 1, to: 2, type: "reports_to"}
      ]

      graph = D3Ex.Data.to_graph(
        nodes: users,
        links: relationships,
        node_id: :id,
        node_label: :name,
        link_source: :from,
        link_target: :to
      )

      # Returns:
      %{
        nodes: [
          %{id: 1, label: "Alice", group: "Engineering"},
          %{id: 2, label: "Bob", group: "Sales"}
        ],
        links: [
          %{source: 1, target: 2, type: "reports_to"}
        ]
      }
  """
  def to_graph(opts) do
    # Implementation
  end

  @doc """
  Filter data based on predicate.

  ## Example

      data
      |> D3Ex.Data.filter(&(&1.active == true))
      |> D3Ex.Data.filter(&(&1.revenue > 1000))
  """
  def filter(data, predicate) do
    Enum.filter(data, predicate)
  end

  @doc """
  Group data by field.

  ## Example

      sales
      |> D3Ex.Data.group_by(:region)
      |> D3Ex.Data.aggregate(:sum, :amount)
  """
  def group_by(data, field) do
    Enum.group_by(data, &Map.get(&1, field))
  end

  @doc """
  Aggregate grouped data.

  ## Operations

  - `:sum` - Sum of values
  - `:avg` - Average of values
  - `:count` - Count of items
  - `:min` - Minimum value
  - `:max` - Maximum value

  ## Example

      sales
      |> D3Ex.Data.group_by(:category)
      |> D3Ex.Data.aggregate(:sum, :revenue)

      # Returns:
      [
        %{category: "Electronics", sum_revenue: 50000},
        %{category: "Books", sum_revenue: 20000}
      ]
  """
  def aggregate(grouped_data, operation, field) do
    # Implementation
  end
end
```

---

## Config Helpers Implementation Example

```elixir
defmodule D3Ex.Config do
  @moduledoc """
  Configuration builders for D3 components.

  Provides helpers to build common configuration patterns.
  """

  @doc """
  Build force configuration for network graphs.

  ## Example

      config = D3Ex.Config.forces(
        charge: -300,
        link: [distance: 100, strength: 1],
        collision: 15,
        center: 0.1
      )
  """
  def forces(opts) do
    %{
      charge: opts[:charge] || -300,
      link: normalize_link_force(opts[:link]),
      collision: normalize_collision_force(opts[:collision]),
      center: opts[:center] || 0.1
    }
  end

  @doc """
  Preset theme configurations.

  ## Themes

  - `:light` - Light background, dark text
  - `:dark` - Dark background, light text
  - `:corporate` - Professional blue theme
  - `:pastel` - Soft pastel colors

  ## Example

      config = D3Ex.Config.theme(:dark)
      |> D3Ex.Config.merge(%{width: 800})
  """
  def theme(:dark) do
    %{
      background: "#1a1a1a",
      text_color: "#ffffff",
      grid_color: "#333333",
      color_scheme: "schemeDark2"
    }
  end

  def theme(:light) do
    %{
      background: "#ffffff",
      text_color: "#000000",
      grid_color: "#e5e5e5",
      color_scheme: "schemeCategory10"
    }
  end

  @doc """
  Build complete network graph configuration.

  ## Example

      config = D3Ex.Config.network_graph(
        size: {800, 600},
        forces: [charge: -400, link: [distance: 150]],
        theme: :dark,
        interactions: [drag: true, zoom: true]
      )
  """
  def network_graph(opts) do
    {width, height} = opts[:size] || {800, 600}

    %{}
    |> Map.merge(theme(opts[:theme] || :light))
    |> Map.merge(%{width: width, height: height})
    |> Map.merge(%{forces: forces(opts[:forces] || [])})
    |> Map.merge(interactions(opts[:interactions] || []))
  end

  @doc """
  Merge two configurations.

  ## Example

      base = D3Ex.Config.theme(:dark)
      custom = %{width: 1000, custom_option: true}

      config = D3Ex.Config.merge(base, custom)
  """
  def merge(config1, config2) do
    Map.merge(config1, config2)
  end
end
```

---

## Why This Approach Works

### ✅ Follows VegaLite.ex Pattern
- Elixir: Data model and configuration
- JavaScript: Rendering and interactions
- Clean separation of concerns

### ✅ Minimal Maintenance
- No need to replicate entire D3 API
- D3 version updates don't break library
- Focus on what Elixir is good at (data transformation)

### ✅ Maximum Flexibility
- Helpers for common cases (easy)
- Code injection for advanced cases (powerful)
- Direct D3 access when needed (escape hatch)

### ✅ Performance
- Only data transferred over wire
- D3 runs directly in browser
- No AST interpretation overhead

---

## Next Steps

1. **Implement `D3Ex.Data` module** ✅
2. **Implement `D3Ex.Config` module** ✅
3. **Update components to support custom D3 injection** ✅
4. **Add comprehensive examples** ✅
5. **Update documentation** ✅

Should I proceed with implementing Phase 1 (Data + Config helpers)?
