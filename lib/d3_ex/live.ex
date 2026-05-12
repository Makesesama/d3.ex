defmodule D3Ex.Live do
  @moduledoc """
  Helpers to stream chart updates from a LiveView to a D3 hook over the
  WebSocket, bypassing the assign/re-render path.

  All events are scoped per element id (e.g. `"sales:set_data"`) so multiple
  charts on the same page don't cross-talk.

  ## Why this exists

  Re-assigning chart data (`assign(socket, data: new_data)`) re-renders the
  component wrapper. Even with `phx-update="ignore"`, the wrapper's
  `data-items` attribute still diffs and the full dataset re-serializes over
  the wire on every update. For streaming feeds that's the dominant cost.

  These helpers `push_event/3` an id-scoped event instead, which the hook
  applies directly to its in-memory dataset.

  ## Operations

    * `set_data/3` — full replace
    * `append/3` — append items (streaming feeds)
    * `patch/3` — partial updates keyed by identity
    * `remove/3` — remove items by identity

  ## Custom operations

  These four are conventions, not magic — your hook just listens to
  `"\#{el.id}:set_data"` etc. If you need a different operation, push the
  event directly:

      push_event(socket, "graph:add_node", %{node: %{id: "n3", label: "C"}})

  and have your hook subscribe via `bindDataEvents({ add_node: ... })` or
  the `events:` option to `createD3Hook`.

  ## Reconnect

  Because `phx-update="ignore"` preserves the wrapper across LiveView
  reconnects, `mounted()` does not re-run and the initial `data-*` attribute
  is not re-read. The chart keeps showing the last client-side state.
  Callers who need reconnect-safe behavior should mirror their data into
  assigns *and* push deltas — accepting the assign cost for the reconnect
  case — or use Phoenix `stream/3` with a MutationObserver-based hook (see
  the StreamChart example in the demo app).
  """

  alias Phoenix.LiveView

  @doc """
  Replace the chart's dataset with `data`.

      D3Ex.Live.set_data(socket, "sales-chart", new_dataset)
  """
  def set_data(socket, id, data) when is_binary(id) do
    LiveView.push_event(socket, "#{id}:set_data", %{data: data})
  end

  @doc """
  Append items to the chart's dataset.

      D3Ex.Live.append(socket, "metrics-chart", [%{t: ..., value: 42}])
  """
  def append(socket, id, items) when is_binary(id) and is_list(items) do
    LiveView.push_event(socket, "#{id}:append", %{items: items})
  end

  @doc """
  Update items in place by identity key.

  `changes` is a list of `%{key: identity_value, changes: %{...}}` maps.
  The hook resolves identity using whatever key it considers identity
  (e.g. `x_key` for a bar chart).

      D3Ex.Live.patch(socket, "sales-chart", [
        %{key: "Feb", changes: %{sales: 13_000}}
      ])
  """
  def patch(socket, id, changes) when is_binary(id) and is_list(changes) do
    LiveView.push_event(socket, "#{id}:patch", %{changes: changes})
  end

  @doc """
  Remove items by identity key.

      D3Ex.Live.remove(socket, "sales-chart", ["Jan", "Feb"])
  """
  def remove(socket, id, ids) when is_binary(id) and is_list(ids) do
    LiveView.push_event(socket, "#{id}:remove", %{ids: ids})
  end
end
