# Simple test script for D3Ex helpers (without Phoenix dependencies)

Code.require_file("lib/d3_ex/data.ex")
Code.require_file("lib/d3_ex/config.ex")

defmodule SimpleTest do
  def run do
    IO.puts("\n=== Testing D3Ex.Data ===\n")
    test_data_filter()
    test_data_group_and_aggregate()
    test_data_sort()
    test_data_to_graph()
    test_data_pipeline()

    IO.puts("\n=== Testing D3Ex.Config ===\n")
    test_config_forces()
    test_config_themes()
    test_config_network_graph()
    test_config_merge()

    IO.puts("\n✅ All tests passed!")
  end

  # D3Ex.Data tests

  defp test_data_filter do
    data = [
      %{name: "Alice", active: true, score: 90},
      %{name: "Bob", active: false, score: 80},
      %{name: "Charlie", active: true, score: 95}
    ]

    result = D3Ex.Data.filter(data, & &1.active)
    assert length(result) == 2, "Filter should return 2 active items"
    assert Enum.all?(result, & &1.active), "All results should be active"

    IO.puts("✓ filter/2 works correctly")
  end

  defp test_data_group_and_aggregate do
    data = [
      %{category: "A", amount: 100},
      %{category: "A", amount: 150},
      %{category: "B", amount: 200}
    ]

    grouped = D3Ex.Data.group_by(data, :category)
    assert map_size(grouped) == 2, "Should have 2 groups"

    aggregated = D3Ex.Data.aggregate(grouped, :sum, :amount)
    a_result = Enum.find(aggregated, &(&1.category == "A"))
    assert a_result.sum_amount == 250, "Category A sum should be 250"

    IO.puts("✓ group_by/2 and aggregate/3 work correctly")
  end

  defp test_data_sort do
    data = [
      %{name: "Charlie", score: 70},
      %{name: "Alice", score: 90},
      %{name: "Bob", score: 80}
    ]

    # Test ascending
    asc_result = D3Ex.Data.sort_by(data, :score)
    assert Enum.map(asc_result, & &1.score) == [70, 80, 90], "Should sort ascending by default"

    # Test descending
    desc_result = D3Ex.Data.sort_by(data, :score, :desc)
    assert Enum.map(desc_result, & &1.score) == [90, 80, 70], "Should sort descending"

    # Test function sort
    fn_result = D3Ex.Data.sort_by(data, fn item -> item.score end)
    assert Enum.map(fn_result, & &1.score) == [70, 80, 90], "Should sort by function"

    IO.puts("✓ sort_by/2 and sort_by/3 work correctly")
  end

  defp test_data_to_graph do
    nodes = [
      %{id: 1, name: "Alice", dept: "eng"},
      %{id: 2, name: "Bob", dept: "sales"}
    ]

    links = [
      %{source: 1, target: 2, weight: 5}
    ]

    result =
      D3Ex.Data.to_graph(
        nodes: nodes,
        links: links,
        node_id: :id,
        node_label: :name,
        node_group: :dept
      )

    assert length(result.nodes) == 2, "Should have 2 nodes"
    assert length(result.links) == 1, "Should have 1 link"

    first_node = hd(result.nodes)
    assert first_node.id == 1, "Node should have correct id"
    assert first_node.label == "Alice", "Node should have correct label"
    assert first_node.group == "eng", "Node should have correct group"

    first_link = hd(result.links)
    assert first_link.source == 1, "Link should have correct source"
    assert first_link.target == 2, "Link should have correct target"
    assert first_link.weight == 5, "Link should preserve extra fields"

    IO.puts("✓ to_graph/1 works correctly")
  end

  defp test_data_pipeline do
    sales = [
      %{category: "A", amount: 100, active: true},
      %{category: "A", amount: 150, active: true},
      %{category: "B", amount: 200, active: true},
      %{category: "C", amount: 50, active: false}
    ]

    result =
      sales
      |> D3Ex.Data.filter(& &1.active)
      |> D3Ex.Data.group_by(:category)
      |> D3Ex.Data.aggregate(:sum, :amount)
      |> D3Ex.Data.sort_by(:sum_amount, :desc)
      |> D3Ex.Data.limit(2)

    assert length(result) == 2, "Should have 2 results after limit"
    assert hd(result).sum_amount == 250, "First result should be highest sum"

    IO.puts("✓ Full pipeline works correctly")
  end

  # D3Ex.Config tests

  defp test_config_forces do
    config = D3Ex.Config.forces(charge: -500, link: 150, collision: 20)

    assert config.charge == -500, "Charge should be -500"
    assert config.link.distance == 150, "Link distance should be 150"
    assert config.collision.radius == 20, "Collision radius should be 20"

    IO.puts("✓ forces/1 works correctly")
  end

  defp test_config_themes do
    dark = D3Ex.Config.theme(:dark)
    assert dark.background == "#1a1a1a", "Dark theme should have dark background"

    light = D3Ex.Config.theme(:light)
    assert light.background == "#ffffff", "Light theme should have light background"

    IO.puts("✓ theme/1 works correctly")
  end

  defp test_config_network_graph do
    config =
      D3Ex.Config.network_graph(
        size: {1000, 800},
        forces: [charge: -400],
        theme: :dark
      )

    assert config.width == 1000, "Width should be 1000"
    assert config.height == 800, "Height should be 800"
    assert config.forces.charge == -400, "Should include force config"
    assert config.background == "#1a1a1a", "Should apply theme"

    IO.puts("✓ network_graph/1 works correctly")
  end

  defp test_config_merge do
    base = D3Ex.Config.theme(:dark)
    custom = %{width: 1200, custom_option: true}

    result = D3Ex.Config.merge(base, custom)

    assert result.background == "#1a1a1a", "Should preserve base config"
    assert result.width == 1200, "Should add custom config"
    assert result.custom_option == true, "Should include all custom fields"

    IO.puts("✓ merge/2 works correctly")
  end

  # Helper assertion function
  defp assert(condition, message) do
    unless condition do
      raise "Assertion failed: #{message}"
    end
  end
end

# Run the tests
SimpleTest.run()
