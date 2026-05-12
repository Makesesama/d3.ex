defmodule D3ExDemoWeb.NetworkGraphLive do
  use D3ExDemoWeb, :live_view

  import D3ExDemoWeb.Components.Charts.NetworkGraph

  @initial_nodes [
    %{id: "alice", label: "Alice", group: "A"},
    %{id: "bob", label: "Bob", group: "B"},
    %{id: "carol", label: "Carol", group: "A"},
    %{id: "dave", label: "Dave", group: "C"},
    %{id: "eve", label: "Eve", group: "B"}
  ]

  @initial_links [
    %{source: "alice", target: "bob"},
    %{source: "alice", target: "carol"},
    %{source: "bob", target: "dave"},
    %{source: "carol", target: "eve"},
    %{source: "dave", target: "eve"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Network graph")
     |> assign(:initial_nodes, @initial_nodes)
     |> assign(:initial_links, @initial_links)
     |> assign(:nodes, @initial_nodes)
     |> assign(:selected, nil)
     |> assign(:last_action, nil)}
  end

  @impl true
  def handle_event("add_node", _params, socket) do
    new_node = %{
      id: "n#{System.unique_integer([:positive])}",
      label: "Node #{length(socket.assigns.nodes) + 1}",
      group: Enum.random(["A", "B", "C"])
    }

    target = Enum.random(socket.assigns.nodes)

    {:noreply,
     socket
     |> push_event("graph:add_node", %{node: new_node})
     |> push_event("graph:add_link", %{link: %{source: new_node.id, target: target.id}})
     |> update(:nodes, &(&1 ++ [new_node]))
     |> assign(:last_action, "added #{new_node.label}, linked to #{target.label}")}
  end

  @impl true
  def handle_event("remove_selected", _params, %{assigns: %{selected: nil}} = socket) do
    {:noreply, assign(socket, :last_action, "no node selected — click one first")}
  end

  def handle_event("remove_selected", _params, socket) do
    selected = socket.assigns.selected

    {:noreply,
     socket
     |> push_event("graph:remove_node", %{id: selected})
     |> update(:nodes, fn nodes -> Enum.reject(nodes, &(&1.id == selected)) end)
     |> assign(:selected, nil)
     |> assign(:last_action, "removed node #{selected}")}
  end

  @impl true
  def handle_event("node_selected", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected: id, last_action: "selected #{id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-6 py-8 space-y-6">
      <header class="space-y-1">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:underline">
          ← home
        </.link>
        <h1 class="text-2xl font-semibold">Network graph</h1>
        <p class="text-sm text-base-content/70">
          Drag nodes around — the force simulation runs client-side. Adding a
          node pushes only that node + its new edge over the wire.
        </p>
      </header>

      <.network_graph
        id="graph"
        initial_nodes={@initial_nodes}
        initial_links={@initial_links}
        selected={@selected}
        on_select="node_selected"
        width={800}
        height={500}
        charge_strength={-400}
        link_distance={120}
      />

      <div class="flex flex-wrap gap-2">
        <button
          phx-click="add_node"
          class="rounded border px-3 py-1.5 text-sm hover:bg-base-200"
        >
          add_node (+ link)
        </button>
        <button
          phx-click="remove_selected"
          class="rounded border px-3 py-1.5 text-sm hover:bg-base-200"
        >
          remove selected
        </button>
      </div>

      <div :if={@last_action} class="text-sm text-base-content/70">
        <strong>Last action:</strong> {@last_action}
      </div>
    </div>
    """
  end
end
