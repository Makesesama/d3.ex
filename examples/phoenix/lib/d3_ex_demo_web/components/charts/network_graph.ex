defmodule D3ExDemoWeb.Components.Charts.NetworkGraph do
  @moduledoc """
  Example force-directed network graph built on `D3Ex.Component`. Lives in the
  demo app, not the library — D3Ex itself ships only the bridge primitives.

  Pairs with `assets/js/hooks/network_graph.js`.

  ## Example

      <.network_graph
        id="my-graph"
        initial_nodes={@nodes}
        initial_links={@links}
        selected={@selected_node_id}
        on_select="node_selected"
        width={800}
        height={600}
      />

  `:initial_nodes` and `:initial_links` are consumed once at mount. Stream
  subsequent updates by pushing id-scoped events directly, e.g.:

      push_event(socket, "my-graph:add_node", %{node: %{id: "n3", label: "C"}})
      push_event(socket, "my-graph:add_link", %{link: %{source: "n1", target: "n2"}})

  See the JS hook for the event names it listens for.

  ## Options

  - `initial_nodes` - Maps with at least `:id` (and optional `:label`, `:group`)
  - `initial_links` - Maps with `:source` and `:target` (matching node ids)
  - `selected` - ID of the currently selected node
  - `on_select`, `on_position_save`, `on_link_click` - LiveView event names
  - `width`, `height`, `charge_strength`, `link_distance`, `node_radius`,
    `color_scheme`, `enable_zoom`, `enable_drag`, `collision_radius`,
    `center_force` - Layout/visual config
  """

  use D3Ex.Component

  @impl true
  def default_config do
    %{
      width: 800,
      height: 600,
      charge_strength: -300,
      link_distance: 100,
      node_radius: 10,
      color_scheme: "schemeCategory10",
      enable_zoom: true,
      enable_drag: true,
      collision_radius: 15,
      center_force: 0.1
    }
  end

  @impl true
  def prepare_assigns(assigns) do
    assigns
    |> Map.put_new(:initial_nodes, [])
    |> Map.put_new(:initial_links, [])
    |> Map.put_new(:selected, nil)
    |> Map.put_new(:on_select, nil)
    |> Map.put_new(:on_position_save, nil)
    |> Map.put_new(:on_link_click, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="D3NetworkGraph"
      data-nodes={encode_data(@initial_nodes)}
      data-links={encode_data(@initial_links)}
      data-config={encode_config(@config)}
      data-selected={@selected}
      data-events={encode_events(%{
        on_select: @on_select,
        on_position_save: @on_position_save,
        on_link_click: @on_link_click
      })}
      phx-update="ignore"
      class="d3-network-graph"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>
    </div>
    """
  end
end
