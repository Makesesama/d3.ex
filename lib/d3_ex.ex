defmodule D3Ex do
  @moduledoc """
  D3Ex provides seamless integration between D3.js and Phoenix LiveView.

  This library implements a minimal state synchronization strategy where:
  - LiveView manages data and essential state (current items, selections)
  - D3.js owns all visual rendering and high-frequency interactions
  - Only important state changes flow between server and client

  ## Architecture

  The library uses a "thin server, rich client" model:

  1. **Server Side (Elixir/LiveView)**:
     - Manages data state (`@items`, `@selected_item`)
     - Pushes data updates via `push_event/3`
     - Handles important events from client (selections, final positions)

  2. **Client Side (D3.js + LiveView Hooks)**:
     - Owns all visual state (positions, zoom, animations)
     - Handles high-frequency interactions (dragging, panning)
     - Sends throttled/debounced updates back to server

  ## Benefits

  - **High Performance**: Minimal WebSocket traffic, no DOM diffing for visualizations
  - **Responsive UI**: D3.js handles interactions at 60fps
  - **Scalable**: Server focuses on data, not visual pixels
  - **Real-time**: LiveView provides instant data sync across clients

  ## Usage

  Add to your LiveView:

      defmodule MyAppWeb.GraphLive do
        use Phoenix.LiveView
        import D3Ex.Components.NetworkGraph

        def mount(_params, _session, socket) do
          {:ok, assign(socket,
            nodes: [
              %{id: "1", label: "Node 1"},
              %{id: "2", label: "Node 2"}
            ],
            links: [
              %{source: "1", target: "2"}
            ],
            selected_node: nil
          )}
        end

        def handle_event("node_selected", %{"id" => id}, socket) do
          {:noreply, assign(socket, selected_node: id)}
        end
      end

  In your template:

      <.network_graph
        id="my-graph"
        nodes={@nodes}
        links={@links}
        on_select="node_selected"
        selected={@selected_node}
      />

  ## Available Components

  - `D3Ex.Components.NetworkGraph` - Force-directed network graphs
  - `D3Ex.Components.BarChart` - Bar charts with animations
  - `D3Ex.Components.LineChart` - Line/area charts
  - `D3Ex.Components.ScatterPlot` - Scatter plots with brushing

  See individual component documentation for detailed options.

  ## Setup

  To include D3.js in your application, add to your root layout:

      <D3Ex.Helpers.d3_script />

  This loads the bundled D3.js library from your server.
  """

  @doc """
  Returns the version of D3Ex.
  """
  def version, do: unquote(Mix.Project.config()[:version])
end
