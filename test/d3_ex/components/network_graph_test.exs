defmodule D3Ex.Components.NetworkGraphTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import D3Ex.Components.NetworkGraph, only: [component: 1]

  defp extract_data_events(html) do
    [_, escaped] = Regex.run(~r/data-events="([^"]*)"/, html)

    escaped
    |> String.replace("&quot;", "\"")
    |> String.replace("&amp;", "&")
    |> Jason.decode!()
  end

  describe "network_graph component" do
    test "renders with minimal data" do
      assigns = %{
        id: "test-graph",
        initial_nodes: [%{id: "1", label: "Node 1"}],
        initial_links: []
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "id=\"test-graph\""
      assert result =~ "phx-hook=\"D3NetworkGraph\""
      assert result =~ "data-nodes="
      assert result =~ "data-links="
    end

    test "renders with nodes and links" do
      nodes = [
        %{id: "1", label: "Alice"},
        %{id: "2", label: "Bob"}
      ]

      assigns = %{
        id: "graph",
        initial_nodes: nodes,
        initial_links: [%{source: "1", target: "2"}]
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "data-nodes="

      assert result =~
               Jason.encode!(nodes) |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    end

    test "includes selected node" do
      assigns = %{
        id: "graph",
        initial_nodes: [%{id: "1", label: "Node"}],
        initial_links: [],
        selected: "1"
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "data-selected=\"1\""
    end

    test "includes event handlers in data-events" do
      assigns = %{
        id: "graph",
        initial_nodes: [],
        initial_links: [],
        on_select: "node_selected",
        on_position_save: "pos_saved"
      }

      result = rendered_to_string(component(assigns))

      events = extract_data_events(result)
      assert events == %{"on_select" => "node_selected", "on_position_save" => "pos_saved"}
      refute result =~ "<input"
    end

    test "omits unset handlers from data-events" do
      assigns = %{
        id: "graph",
        initial_nodes: [],
        initial_links: [],
        on_select: "node_selected"
      }

      result = rendered_to_string(component(assigns))

      assert extract_data_events(result) == %{"on_select" => "node_selected"}
    end

    test "renders empty data-events when no handlers wired" do
      assigns = %{id: "graph", initial_nodes: [], initial_links: []}

      result = rendered_to_string(component(assigns))

      assert extract_data_events(result) == %{}
    end

    test "applies custom configuration" do
      assigns = %{
        id: "graph",
        initial_nodes: [],
        initial_links: [],
        width: 1000,
        height: 800,
        charge_strength: -500
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "width: 1000px"
      assert result =~ "height: 800px"
      assert result =~ "width=\"1000\""
      assert result =~ "height=\"800\""
    end

    test "uses default configuration when not specified" do
      assigns = %{
        id: "graph",
        initial_nodes: [],
        initial_links: []
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "width=\"800\""
      assert result =~ "height=\"600\""
    end

    test "includes phx-update ignore" do
      assigns = %{
        id: "graph",
        initial_nodes: [],
        initial_links: []
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "phx-update=\"ignore\""
    end

    test "handles empty data gracefully" do
      assigns = %{
        id: "empty-graph",
        initial_nodes: [],
        initial_links: []
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "data-nodes=\"[]\""
      assert result =~ "data-links=\"[]\""
    end
  end

  describe "deprecated props" do
    test "raises with migration message when :nodes is passed" do
      assigns = %{id: "g", nodes: [], initial_links: []}

      assert_raise ArgumentError, ~r/:nodes.*Rename.*initial_nodes/s, fn ->
        rendered_to_string(component(assigns))
      end
    end

    test "raises with migration message when :links is passed" do
      assigns = %{id: "g", initial_nodes: [], links: []}

      assert_raise ArgumentError, ~r/:links.*Rename.*initial_links/s, fn ->
        rendered_to_string(component(assigns))
      end
    end
  end
end
