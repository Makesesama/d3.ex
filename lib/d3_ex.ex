defmodule D3Ex do
  @moduledoc """
  Minimal bridge between D3.js and Phoenix LiveView.

  D3Ex ships no chart implementations. It gives you two things:

    * `D3Ex.Component` — a Phoenix component behavior with helpers to JSON-
      encode data/config/events into `data-*` attributes a JS hook can read.
    * `D3Ex.Live` — `push_event` helpers (`set_data/3`, `append/3`, `patch/3`,
      `remove/3`) that target a chart by id, so multiple charts on a page do
      not cross-talk.

  On the JS side (`priv/static/js/d3_hooks.js`) it ships:

    * `D3Hook` — a mixin of helpers (`getConfig`, `getData`, `sendEvent`,
      `bindDataEvents`, ...).
    * `createD3Hook` — a factory that bundles the `mounted`/`updated`/
      `destroyed` lifecycle, config parsing, and id-scoped event wiring.

  ## Writing a chart

  Three steps: an Elixir component, a JS hook, and a LiveView that uses them.
  See the `README` and the `examples/phoenix/` demo app for complete working
  patterns (bar, line, network graph, Phoenix `stream/3` bridge).

  ## Streaming updates after mount

  `:initial_data` (or whatever you name it on your component) is consumed
  once at mount. For everything after that, push deltas:

      D3Ex.Live.set_data(socket, "sales", new_data)
      D3Ex.Live.append(socket, "metrics", [%{t: ..., value: 42}])
      D3Ex.Live.patch(socket, "sales", [%{key: "Feb", changes: %{sales: 13_000}}])
      D3Ex.Live.remove(socket, "sales", ["Jan"])

  Or push directly for custom ops:

      push_event(socket, "graph:add_node", %{node: ...})

  Your hook subscribes via the `events:` option to `createD3Hook` (or
  `bindDataEvents/1` directly).
  """

  @doc "Returns the version of D3Ex."
  def version, do: unquote(Mix.Project.config()[:version])
end
