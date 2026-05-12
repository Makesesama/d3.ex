defmodule D3Ex.Live do
  @moduledoc """
  Imperative helpers for streaming chart updates from a LiveView to a D3Ex
  hook over the WebSocket, bypassing the assign/re-render path.

  All events are scoped per element id so multiple charts on the same page
  don't cross-talk.

  ## Why this exists

  Re-assigning chart data (`assign(socket, data: new_data)`) re-renders the
  component wrapper. Even with `phx-update="ignore"`, the wrapper's
  `data-items` attribute still diffs, and the full dataset re-serializes
  over the wire on every update. For streaming feeds this is the dominant
  cost.

  Use these helpers for any data change *after* initial mount. The
  `initial_data` prop on the component still ships the first dataset via
  server render — these helpers handle everything after that.

  ## Operations

  - `set_data/3` — full replace
  - `append/3` — append items (streaming feeds)
  - `patch/3` — partial updates by identity key
  - `remove/3` — remove items by identity key

  ## Network graph specifics

  Network graphs have richer semantics (nodes + links). The network helpers
  emit per-op event names: `add_node`, `remove_node`, `update_node`,
  `add_link`, `remove_link`.

  ## Reconnect

  Because `phx-update="ignore"` preserves the wrapper across LiveView
  reconnects, `mounted()` does not re-run and `data-items` is not re-read.
  The chart keeps showing the last client-side state. Callers who need
  reconnect-safe behavior should mirror their data into assigns *and* push
  deltas — accepting the assign cost for the reconnect case.

  ## Identity key for patch/remove

  Each hook knows its identity key from config (e.g. the `x_key` for bar
  charts, `:id` for network nodes). Server-side, callers pass identity
  values directly; the hook resolves matches client-side.
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

      D3Ex.Live.append(socket, "metrics-chart", [%{timestamp: ..., value: 42}])
  """
  def append(socket, id, items) when is_binary(id) and is_list(items) do
    LiveView.push_event(socket, "#{id}:append", %{items: items})
  end

  @doc """
  Update items in place by identity key.

  `changes` is a list of `%{key: identity_value, changes: %{...}}` maps.
  The hook resolves identity using its configured identity key.

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

  @doc """
  Add a node to a network graph.

      D3Ex.Live.add_node(socket, "entity-graph", %{id: "n1", label: "Alice"})
  """
  def add_node(socket, id, node) when is_binary(id) do
    LiveView.push_event(socket, "#{id}:add_node", %{node: node})
  end

  @doc """
  Remove a node (and its incident links) from a network graph.
  """
  def remove_node(socket, id, node_id) when is_binary(id) do
    LiveView.push_event(socket, "#{id}:remove_node", %{id: node_id})
  end

  @doc """
  Update a node's fields in place.

      D3Ex.Live.update_node(socket, "entity-graph", "n1", %{label: "Alice (updated)"})
  """
  def update_node(socket, id, node_id, changes) when is_binary(id) do
    LiveView.push_event(socket, "#{id}:update_node", %{id: node_id, changes: changes})
  end

  @doc """
  Add a link to a network graph.

      D3Ex.Live.add_link(socket, "entity-graph", %{source: "n1", target: "n2"})
  """
  def add_link(socket, id, link) when is_binary(id) do
    LiveView.push_event(socket, "#{id}:add_link", %{link: link})
  end

  @doc """
  Remove a link from a network graph by `source`/`target` ids.
  """
  def remove_link(socket, id, source, target) when is_binary(id) do
    LiveView.push_event(socket, "#{id}:remove_link", %{source: source, target: target})
  end
end
