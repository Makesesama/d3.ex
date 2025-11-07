defmodule D3Ex.Examples.NetworkGraphLive do
  @moduledoc """
  Example LiveView demonstrating network graph with minimal state synchronization.

  This example shows:
  - Force-directed network graph
  - Node selection with server-side state
  - Real-time data updates
  - Efficient position tracking (only on drag end)
  """

  use Phoenix.LiveView
  import D3Ex.Components.NetworkGraph

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:selected_node, nil)
     |> assign(:nodes, initial_nodes())
     |> assign(:links, initial_links())
     |> assign(:saved_positions, %{})}
  end

  @impl true
  def handle_event("node_selected", %{"id" => id}, socket) do
    # Update server state with selected node
    {:noreply, assign(socket, :selected_node, id)}
  end

  @impl true
  def handle_event("position_saved", %{"id" => id, "x" => x, "y" => y}, socket) do
    # Save final position after drag ends (debounced from client)
    positions = Map.put(socket.assigns.saved_positions, id, %{x: x, y: y})

    # Optionally persist to database
    # Graph.update_node_position(id, x, y)

    {:noreply, assign(socket, :saved_positions, positions)}
  end

  @impl true
  def handle_event("add_random_node", _params, socket) do
    # Example: Add a new node dynamically
    new_node = %{
      id: "node_#{:rand.uniform(10000)}",
      label: "Node #{length(socket.assigns.nodes) + 1}",
      group: Enum.random(["A", "B", "C"])
    }

    # Could also use incremental update:
    # push_event(socket, "graph:add_node", %{node: new_node})

    {:noreply,
     socket
     |> update(:nodes, &(&1 ++ [new_node]))
     |> maybe_link_to_existing_node(new_node)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-3xl font-bold mb-6">Network Graph Example</h1>

      <div class="mb-4 space-x-2">
        <button
          phx-click="add_random_node"
          class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          Add Random Node
        </button>

        <%= if @selected_node do %>
          <div class="inline-block px-4 py-2 bg-green-100 text-green-800 rounded">
            Selected: <%= @selected_node %>
          </div>
        <% end %>
      </div>

      <div class="border border-gray-300 rounded-lg overflow-hidden">
        <.network_graph
          id="example-graph"
          nodes={@nodes}
          links={@links}
          selected={@selected_node}
          on_select="node_selected"
          on_position_save="position_saved"
          width={1000}
          height={600}
          charge_strength={-400}
          link_distance={120}
        />
      </div>

      <div class="mt-6 p-4 bg-gray-100 rounded">
        <h2 class="text-xl font-semibold mb-2">Graph Info</h2>
        <p>Nodes: <%= length(@nodes) %></p>
        <p>Links: <%= length(@links) %></p>
        <p>Saved Positions: <%= map_size(@saved_positions) %></p>
      </div>
    </div>
    """
  end

  # Helper functions

  defp initial_nodes do
    [
      %{id: "1", label: "Alice", group: "A"},
      %{id: "2", label: "Bob", group: "B"},
      %{id: "3", label: "Charlie", group: "A"},
      %{id: "4", label: "David", group: "C"},
      %{id: "5", label: "Eve", group: "B"},
      %{id: "6", label: "Frank", group: "C"},
      %{id: "7", label: "Grace", group: "A"},
      %{id: "8", label: "Henry", group: "B"}
    ]
  end

  defp initial_links do
    [
      %{source: "1", target: "2"},
      %{source: "2", target: "3"},
      %{source: "3", target: "4"},
      %{source: "4", target: "5"},
      %{source: "5", target: "6"},
      %{source: "6", target: "7"},
      %{source: "7", target: "8"},
      %{source: "8", target: "1"},
      %{source: "1", target: "5"},
      %{source: "2", target: "6"},
      %{source: "3", target: "7"},
      %{source: "4", target: "8"}
    ]
  end

  defp maybe_link_to_existing_node(socket, new_node) do
    # Link new node to a random existing node
    existing_nodes = socket.assigns.nodes

    if length(existing_nodes) > 0 do
      random_target = Enum.random(existing_nodes).id

      new_link = %{source: new_node.id, target: random_target}

      update(socket, :links, &(&1 ++ [new_link]))
    else
      socket
    end
  end
end
