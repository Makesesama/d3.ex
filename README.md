# D3Ex

A minimal bridge between [D3.js](https://d3js.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/). D3Ex gives you the wiring — id-scoped event channels, JSON-encoded `data-*` attributes, a hook lifecycle factory — and gets out of your way so you can write D3 the way the D3 docs show you.

It ships **no chart implementations**. There is no `BarChart` macro. No theme presets, no data-transformation DSL, no preset color schemes. Charts live in your app, where you already know what x-axis formatting and tooltip wording you want.

## What you get

**Elixir (`lib/`)** — ~250 LOC:

- `D3Ex.Component` — a Phoenix component behavior with helpers (`encode_data/1`, `encode_config/1`, `encode_events/1`, `merge_config/2`, `ensure_id/1`).
- `D3Ex.Live` — four `push_event` helpers (`set_data/3`, `append/3`, `patch/3`, `remove/3`) that target an element by id so multiple charts on a page don't cross-talk.

**JavaScript (`priv/static/js/d3_hooks.js`)** — ~250 LOC:

- `D3Hook` — a mixin: `getConfig`, `getData`, `getLinks`, `getSelected`, `getEvents`, `sendEvent`, `bindDataEvents`, `cleanup`.
- `createD3Hook({ onMount, onUpdated, onDestroy, events })` — a factory for `D3Ex.Live`-driven charts. Handles `mounted`/`updated`/`destroyed`, parses `data-config` and `data-events`, subscribes to id-scoped events, runs cleanup. You write the D3.
- `createStreamD3Hook({ onMount, onUpdate, parseRow, onDestroy, events })` — same shape, for charts driven by Phoenix `stream/3`. Adds a MutationObserver on the hidden `[data-stream-feed]` child and keeps `this.data` in sync.

That's it. Everything else is up to you.

## Installation

```elixir
def deps do
  [{:d3_ex, "~> 0.2.0"}]
end
```

Load D3 in your layout (CDN, npm, or local copy — D3Ex does not bundle it):

```html
<script src="https://d3js.org/d3.v7.min.js"></script>
```

Import hooks in `assets/js/app.js`:

```js
import { createD3Hook } from "../../deps/d3_ex/priv/static/js/d3_hooks.js"
import { MyPieChart } from "./hooks/pie_chart.js"

new LiveSocket("/live", Socket, {
  hooks: { MyPieChart, /* ... */ }
})
```

## Building a chart

### 1. The Elixir component

```elixir
defmodule MyAppWeb.D3.PieChart do
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
    ~H"""
    <div
      id={@id}
      phx-hook="MyPieChart"
      data-items={encode_data(@initial_data)}
      data-config={encode_config(Map.put(@config, :value_key, @value_key))}
      data-events={encode_events(%{on_slice_click: @on_slice_click})}
      phx-update="ignore"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>
    </div>
    """
  end
end
```

After `import MyAppWeb.D3.PieChart`, use it as `<.pie_chart ... />` — the function name is derived from the module's last segment.

### 2. The JS hook

```js
import { createD3Hook } from "../../deps/d3_ex/priv/static/js/d3_hooks.js"

export const MyPieChart = {
  ...createD3Hook({
    onMount() {
      this.data = this.getData()
      this.initChart()
    },
    // Server emits these via `D3Ex.Live.set_data(socket, "pie", new_data)`,
    // or any custom op via `push_event(socket, "pie:foo", payload)`.
    events: {
      set_data({ data }) { this.data = data; this.renderChart() },
    },
  }),

  initChart() {
    const d3 = window.d3
    const { width, height, inner_radius, value_key } = this.config

    this.svg = d3.select(this.el).select("svg")
    this.g = this.svg.append("g").attr("transform", `translate(${width/2}, ${height/2})`)

    this.pie = d3.pie().value(d => d[value_key])
    this.arc = d3.arc().innerRadius(inner_radius).outerRadius(Math.min(width, height) / 2 - 20)
    this.color = d3.scaleOrdinal(d3.schemeCategory10)

    this.renderChart()
  },

  renderChart() {
    const arcs = this.g.selectAll(".arc").data(this.pie(this.data))

    const enter = arcs.enter().append("g").attr("class", "arc")
    enter.append("path")
      .attr("fill", (d, i) => this.color(i))
      .on("click", (event, d) => this.sendEvent("on_slice_click", d.data))

    enter.merge(arcs).select("path")
      .transition().duration(400)
      .attr("d", this.arc)

    arcs.exit().remove()
  },
}
```

### 3. The LiveView

```elixir
defmodule MyAppWeb.PieLive do
  use MyAppWeb, :live_view
  import MyAppWeb.D3.PieChart

  def mount(_params, _session, socket) do
    {:ok, assign(socket, initial_data: [
      %{label: "A", value: 30},
      %{label: "B", value: 50},
      %{label: "C", value: 20},
    ])}
  end

  def handle_event("slice_clicked", %{"label" => label}, socket) do
    # ...
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.pie_chart id="pie" initial_data={@initial_data} on_slice_click="slice_clicked" />
    """
  end
end
```

## Streaming updates after mount

`:initial_data` is consumed once. For everything after that, push deltas via `D3Ex.Live` — your hook subscribes to the matching op in its `events:` map:

```elixir
# In your LiveView
D3Ex.Live.set_data(socket, "pie", new_data)
D3Ex.Live.append(socket, "pie", [%{label: "D", value: 10}])
D3Ex.Live.patch(socket, "pie", [%{key: "A", changes: %{value: 35}}])
D3Ex.Live.remove(socket, "pie", ["C"])
```

```js
// In your hook
events: {
  set_data({ data })  { this.data = data;                    this.renderChart() },
  append({ items })   { this.data = this.data.concat(items); this.renderChart() },
  patch({ changes })  { this.applyPatch(changes);            this.renderChart() },
  remove({ ids })     { this.applyRemove(ids);               this.renderChart() },
}
```

Custom ops? Just push directly:

```elixir
push_event(socket, "graph:add_node", %{node: %{id: "n3", label: "C"}})
```

```js
events: {
  add_node({ node }) { this.nodes.push(node); this.update() },
}
```

## Phoenix `stream/3` instead of `D3Ex.Live`

For high-frequency feeds (live metrics, ticks), Phoenix's `stream/3` is a great fit: server memory is bounded by `limit:`, and LiveView already defines what "the current dataset" is after a reconnect. Render a hidden `phx-update="stream"` feed of `<div data-x="..." data-y="...">` nodes inside your component; in the hook, use `createStreamD3Hook` and the MutationObserver wiring is taken care of:

```js
import { createStreamD3Hook } from "../../deps/d3_ex/priv/static/js/d3_hooks.js"

export const MyStreamChart = {
  ...createStreamD3Hook({
    onMount()  { this.initChart() },      // this.data already populated
    onUpdate() { this.renderChart() },    // this.data refreshed on every stream change
  }),
  initChart()   { /* ... */ },
  renderChart() { /* reads this.data */ },
}
```

The default row parser reads `data-x`/`data-y`/`data-series` and coerces x/y via `Number()`. For non-numeric data, pass a custom `parseRow(node)` to `createStreamD3Hook`.

See `examples/phoenix/lib/d3_ex_demo_web/components/charts/stream_chart.ex` and the matching `assets/js/hooks/stream_chart.js` for the full picture (Elixir-side template + JS-side hook).

## Examples

The `examples/phoenix/` directory is a real Phoenix app you can `mix phx.server`. It demonstrates:

- `bar_chart_live.ex` — bar chart with `set_data` / `patch` / `remove` buttons
- `line_chart_live.ex` — streaming line chart driven by `D3Ex.Live.append/3`
- `network_graph_live.ex` — force-directed graph with custom `add_node` / `remove_node` ops
- `stream_live.ex` — Phoenix `stream/3` driving a D3 line chart via MutationObserver
- `reactive_live.ex` — server-orchestrated cascade across two charts
- `dashboard_live.ex` — three charts driven by a single tick
- `pie_chart_live.ex` — minimal custom component end-to-end

The chart components in `examples/phoenix/lib/d3_ex_demo_web/components/charts/` and their matching hooks in `examples/phoenix/assets/js/hooks/` are good starting points to copy into your app.

## API reference

### `D3Ex.Component`

```elixir
use D3Ex.Component

@callback default_config() :: map()
@callback prepare_assigns(map) :: map()
@callback render(map) :: Phoenix.LiveView.Rendered.t()
```

Helpers in scope after `use`:

- `ensure_id(assigns)` — generates `"d3ex-#{integer}"` if `:id` is unset
- `encode_data(term)` — `Jason.encode!/1`
- `encode_config(term)` — `Jason.encode!/1`
- `encode_events(%{slot => handler_or_nil})` — drops nils, JSON-encodes
- `merge_config(assigns, defaults)` — merges defaults + `:config` + top-level keys

After `use`, the module defines:
- `component/1` — the renderer
- A function named after the module's last segment (e.g. `pie_chart/1`) that's an alias for `component/1`

### `D3Ex.Live`

```elixir
D3Ex.Live.set_data(socket, id, data)        # emits "#{id}:set_data" with %{data: data}
D3Ex.Live.append(socket, id, items)         # emits "#{id}:append" with %{items: items}
D3Ex.Live.patch(socket, id, changes)        # emits "#{id}:patch" with %{changes: changes}
D3Ex.Live.remove(socket, id, ids)           # emits "#{id}:remove" with %{ids: ids}
```

For anything else: `push_event(socket, "#{id}:my_op", payload)`.

### `D3Hook` (JS)

```js
this.getConfig()      // parsed data-config
this.getData()        // parsed data-items (or data-nodes)
this.getLinks()       // parsed data-links
this.getSelected()    // data-selected scalar
this.getEvents()      // parsed data-events
this.sendEvent(slot, payload, throttleMs = 0)
this.bindDataEvents({ op: fn, ... })  // subscribes to ${el.id}:${op}
this.cleanup()        // stops simulations, clears throttle timers
```

### `createD3Hook(opts)` (JS)

```js
{
  onMount(),       // required — initialize, read initial data, set up D3
  onUpdated(),     // optional — scalar data-* changes (e.g. selection)
  onDestroy(),     // optional — extra teardown
  events: {        // optional — id-scoped event handlers
    set_data(payload) { /* `this` is the hook */ },
    // ...
  },
}
```

`this.config`, `this.events` are populated for you in `mounted()` before `onMount` runs.

### `createStreamD3Hook(opts)` (JS)

```js
{
  onMount(),       // required — initialize; `this.data` already populated
  onUpdate(),      // optional — called after each stream flush; `this.data` refreshed
  parseRow(node),  // optional — override per-row parsing; `this` is the hook
  onDestroy(),     // optional — extra teardown
  events: { ... }, // optional — mix in `D3Ex.Live` push_event ops alongside the stream
}
```

In addition to `this.config` and `this.events`, `this.data` is populated by parsing every `[data-stream-item]` inside the hook's `[data-stream-feed]` before `onMount` runs. A MutationObserver on the feed refreshes `this.data` (microtask-batched so a burst of `stream_insert` calls coalesces into one `onUpdate`).

The default `parseRow` reads `data-x`/`data-y`/`data-series` and coerces x/y via `Number()`, keyed by `config.x_key`/`y_key`/`series_key`. Override to read different attributes or skip coercion.

## Reconnect notes

`phx-update="ignore"` means the wrapper survives reconnects but `mounted()` doesn't re-run. The chart keeps showing the last client-side state — but if the server-side dataset diverged in the meantime, you'll be out of sync.

Three options:

1. **Mirror data into assigns AND push deltas.** Costs the assign serialize on reconnect, but you get correctness.
2. **Use Phoenix `stream/3`.** Reconnect is handled by `phx-update="stream"`. See the stream example.
3. **Push a snapshot on `phx:reconnected`.** Client emits an event when LiveView reconnects; server responds with `D3Ex.Live.set_data/3`.

## License

MIT.
