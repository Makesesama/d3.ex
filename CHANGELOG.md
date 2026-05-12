# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- **`createStreamD3Hook`** (JS) — a sibling to `createD3Hook` for charts driven
  by Phoenix `stream/3`. Wires the MutationObserver on `[data-stream-feed]`,
  parses `[data-stream-item]` nodes into `this.data`, and calls `onUpdate` on
  every flush. Same shape as `createD3Hook` (`onMount` / `onDestroy` /
  `events`) plus `onUpdate` and `parseRow`. The stream example hook drops
  from ~75 lines to ~5 lines of factory wiring.

### Fixed

- Import path in `examples/phoenix/assets/js/hooks/{bar,line,network_graph,
  stream}_chart.js` (was 4 levels up, should be 5) — the example app's
  esbuild build now succeeds.

## [0.2.0] — focused core

D3Ex is now a bridge, not a chart library. The baked-in chart components,
data-transformation DSL, theme presets, and configuration builders are gone.
What's left is the wiring people actually need to use D3 normally with
Phoenix server-side state.

### Removed (breaking)

- **`D3Ex.Data`** — wrappers around `Enum.filter/2`, `group_by/2`,
  `sort_by/3`, `take/2`. Use `Enum` directly.
- **`D3Ex.Config`** — theme presets, force/interaction normalizers,
  responsive shells. Build the config map you want in your own code.
- **`D3Ex.Components`** — stale duplicate of `D3Ex.Component` helpers.
- **`D3Ex.Helpers`** — `d3_script/1` was off-scope. Load D3 the way you load
  any JS dependency (CDN, npm, or local file).
- **`D3Ex.Components.{BarChart, LineChart, NetworkGraph, StreamChart}`** —
  the example chart components moved to `examples/phoenix/lib/d3_ex_demo_web/
  components/charts/`. Their JS hooks moved to `examples/phoenix/assets/js/
  hooks/`. Copy them into your app to use; D3Ex itself ships nothing visual.
- **`D3Ex.Live.{add_node, remove_node, update_node, add_link, remove_link}`** —
  network-graph-specific helpers. Use `push_event(socket, "graph:add_node",
  %{node: ...})` directly.
- **Bundled `d3.v7.min.js`** — load D3 via CDN/npm.
- **Renamed `:data` → `:initial_data` ArgumentErrors** removed from the moved
  chart components.

### Changed

- `D3Ex.Component.merge_config/2` now merges any top-level assign whose key
  exists in `default_config/0`, not just a hardcoded list of five keys.
- `D3Ex.Component.build_event_handlers/2` removed (was unused).

### What's still here

- `D3Ex.Component` — component behavior + encoding helpers (`encode_data/1`,
  `encode_config/1`, `encode_events/1`, `merge_config/2`, `ensure_id/1`).
- `D3Ex.Live` — `set_data/3`, `append/3`, `patch/3`, `remove/3`.
- JS: `D3Hook` + `createD3Hook`.

## [0.1.0] — 2025-01-07

Initial release.
