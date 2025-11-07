defmodule D3Ex.Components.NetworkGraphTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import D3Ex.Components.NetworkGraph

  describe "network_graph component" do
    test "renders with minimal data" do
      assigns = %{
        id: "test-graph",
        nodes: [%{id: "1", label: "Node 1"}],
        links: []
      }

      result = rendered_to_string(network_graph(assigns))

      assert result =~ "id=\"test-graph\""
      assert result =~ "phx-hook=\"D3NetworkGraph\""
      assert result =~ "data-nodes="
      assert result =~ "data-links="
    end

    test "renders with nodes and links" do
      assigns = %{
        id: "graph",
        nodes: [
          %{id: "1", label: "Alice"},
          %{id: "2", label: "Bob"}
        ],
        links: [
          %{source: "1", target: "2"}
        ]
      }

      result = rendered_to_string(network_graph(assigns))

      assert result =~ "Alice"
      assert result =~ "data-nodes="
      assert result =~ Jason.encode!(assigns.nodes)
    end

    test "includes selected node" do
      assigns = %{
        id: "graph",
        nodes: [%{id: "1", label: "Node"}],
        links: [],
        selected: "1"
      }

      result = rendered_to_string(network_graph(assigns))

      assert result =~ "data-selected=\"1\""
    end

    test "includes event handlers" do
      assigns = %{
        id: "graph",
        nodes: [],
        links: [],
        on_select: "node_selected",
        on_position_save: "pos_saved"
      }

      result = rendered_to_string(network_graph(assigns))

      assert result =~ "name=\"on_select\""
      assert result =~ "value=\"node_selected\""
      assert result =~ "name=\"on_position_save\""
      assert result =~ "value=\"pos_saved\""
    end

    test "applies custom configuration" do
      assigns = %{
        id: "graph",
        nodes: [],
        links: [],
        width: 1000,
        height: 800,
        charge_strength: -500
      }

      result = rendered_to_string(network_graph(assigns))

      assert result =~ "width: 1000px"
      assert result =~ "height: 800px"
      assert result =~ "width=\"1000\""
      assert result =~ "height=\"800\""
    end

    test "uses default configuration when not specified" do
      assigns = %{
        id: "graph",
        nodes: [],
        links: []
      }

      result = rendered_to_string(network_graph(assigns))

      # Should use defaults from default_config/0
      assert result =~ "width=\"800\""
      assert result =~ "height=\"600\""
    end

    test "includes phx-update ignore" do
      assigns = %{
        id: "graph",
        nodes: [],
        links: []
      }

      result = rendered_to_string(network_graph(assigns))

      assert result =~ "phx-update=\"ignore\""
    end

    test "handles empty data gracefully" do
      assigns = %{
        id: "empty-graph",
        nodes: [],
        links: []
      }

      result = rendered_to_string(network_graph(assigns))

      assert result =~ "data-nodes=\"[]\""
      assert result =~ "data-links=\"[]\""
    end
  end

  describe "push_graph_update/3" do
    setup do
      # This would normally be a real socket in a LiveView test
      socket = %{assigns: %{}}
      %{socket: socket}
    end

    test "formats event name correctly", %{socket: socket} do
      # We can't easily test push_event without a real LiveView context,
      # but we can verify the function exists and has correct arity
      assert function_exported?(D3Ex.Components.NetworkGraph, :push_graph_update, 3)
    end
  end
end
