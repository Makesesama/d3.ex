# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (breaking — pre-1.0)

- **Chart data updates now stream over `push_event` instead of attribute diffs.**
  Re-assigning `:data` no longer updates the chart after mount; use
  `D3Ex.Live` helpers to push deltas.
- **Renamed component props to reflect one-shot semantics:**
  - `D3Ex.Components.BarChart`, `LineChart`: `:data` → `:initial_data`
  - `D3Ex.Components.NetworkGraph`: `:nodes` → `:initial_nodes`,
    `:links` → `:initial_links`
  Passing the old names raises an `ArgumentError` with a migration hint.
- **Removed `D3Ex.Components.NetworkGraph.push_graph_update/3`.** Use the
  id-scoped helpers on `D3Ex.Live` (`add_node/3`, `remove_node/3`,
  `update_node/4`, `add_link/3`, `remove_link/4`) instead.
- **Removed page-global `graph:*` event listeners.** Events are now scoped
  per element id, so multiple network graphs on a page no longer cross-talk.

### Added

- **`D3Ex.Live`** module — imperative helpers to stream chart updates from a
  LiveView without re-shipping the full dataset:
  - `set_data/3`, `append/3`, `patch/3`, `remove/3` (generic)
  - `add_node/3`, `remove_node/3`, `update_node/4`, `add_link/3`,
    `remove_link/4` (network graph)
  All events are scoped per element id.
- `D3Hook.bindDataEvents(handlers)` JS helper for subscribing to the
  id-scoped event protocol from custom hooks.

### Migration

```elixir
# Before
<.bar_chart id="sales" data={@sales_data} x_key={:month} y_key={:sales} />

def handle_info(:tick, socket) do
  {:noreply, assign(socket, :sales_data, new_data)}
end

# After
<.bar_chart id="sales" initial_data={@sales_data} x_key={:month} y_key={:sales} />

def handle_info(:tick, socket) do
  {:noreply, D3Ex.Live.set_data(socket, "sales", new_data)}
end
```

## [0.1.0] - 2025-01-07

### Added
- Initial release of D3Ex
- Core `D3Ex.Component` behavior for building custom D3 visualizations
- `D3Ex.Components.NetworkGraph` - Force-directed network graphs
- `D3Ex.Components.BarChart` - Animated bar charts
- `D3Ex.Components.LineChart` - Multi-line time series charts
- JavaScript hooks for seamless LiveView integration
- Minimal state synchronization architecture
- Comprehensive documentation and examples
- Example LiveView applications:
  - Network graph with selection and drag
  - Real-time dashboard with multiple charts
  - Custom component building guide
- Test suite with component tests
- MIT License

### Features
- **Performance**: Minimal WebSocket traffic using thin server, rich client model
- **Extensibility**: Easy-to-use component pattern for custom visualizations
- **Real-time**: LiveView integration for instant data synchronization
- **Interactive**: Support for clicks, drags, zooms, and custom events
- **Configurable**: Sensible defaults with full customization options

[Unreleased]: https://github.com/Makesesama/d3.ex/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Makesesama/d3.ex/releases/tag/v0.1.0
