defmodule D3Ex.Components.NetworkGraph do
  @moduledoc """
  Force-directed network graph component using D3.js force simulation.

  This component demonstrates the minimal state synchronization pattern:
  - Server maintains: nodes list, links list, selected node, saved positions
  - Client handles: force simulation, dragging, zooming, rendering
  - Communication: Only on data changes, selection, and final positions

  ## Features

  - Force-directed layout with customizable forces
  - Interactive node dragging with smooth animations
  - Zoom and pan capabilities
  - Node selection with server-side state sync
  - Real-time updates when data changes
  - Efficient rendering for large graphs (1000+ nodes)

  ## Example

      <.network_graph
        id="my-graph"
        nodes={@nodes}
        links={@links}
        selected={@selected_node_id}
        on_select="node_selected"
        on_position_save="positions_updated"
        width={800}
        height={600}
      />

  ## Node Format

  Nodes should be maps with at least an `:id` field:

      %{
        id: "node1",
        label: "Node 1",
        group: "type_a",  # optional, for coloring
        x: 100,           # optional, saved position
        y: 200            # optional, saved position
      }

  ## Link Format

  Links should be maps with `:source` and `:target` fields:

      %{
        source: "node1",  # node id
        target: "node2",  # node id
        value: 5          # optional, affects link thickness
      }

  ## Events

  - `on_select` - Fired when a node is clicked. Receives `%{id: node_id}`
  - `on_position_save` - Fired when drag ends. Receives `%{id: node_id, x: x, y: y}`
  - `on_link_click` - Fired when a link is clicked. Receives `%{source: id, target: id}`

  ## Configuration Options

  - `width` - Canvas width in pixels (default: 800)
  - `height` - Canvas height in pixels (default: 600)
  - `charge_strength` - Force strength for node repulsion (default: -300)
  - `link_distance` - Target distance between linked nodes (default: 100)
  - `node_radius` - Node circle radius (default: 10)
  - `color_scheme` - D3 color scheme name (default: "schemeCategory10")
  - `enable_zoom` - Enable zoom and pan (default: true)
  - `enable_drag` - Enable node dragging (default: true)
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
    # Ensure required fields exist
    assigns
    |> Map.put_new(:nodes, [])
    |> Map.put_new(:links, [])
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
      data-nodes={encode_data(@nodes)}
      data-links={encode_data(@links)}
      data-config={encode_config(@config)}
      data-selected={@selected}
      phx-update="ignore"
      class="d3-network-graph"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}>
        <g class="links"></g>
        <g class="nodes"></g>
      </svg>

      <%= if @on_select do %>
        <input type="hidden" name="on_select" value={@on_select} />
      <% end %>

      <%= if @on_position_save do %>
        <input type="hidden" name="on_position_save" value={@on_position_save} />
      <% end %>

      <%= if @on_link_click do %>
        <input type="hidden" name="on_link_click" value={@on_link_click} />
      <% end %>
    </div>
    """
  end

  @doc """
  Helper function to update graph data efficiently.

  Instead of replacing all data, you can push incremental updates:

      push_event(socket, "graph:add_node", %{
        node: %{id: "new_node", label: "New"}
      })

      push_event(socket, "graph:remove_node", %{id: "node_to_remove"})

      push_event(socket, "graph:update_node", %{
        id: "existing_node",
        changes: %{label: "Updated Label"}
      })
  """
  def push_graph_update(socket, action, payload) do
    Phoenix.LiveView.push_event(socket, "graph:#{action}", payload)
  end
end
