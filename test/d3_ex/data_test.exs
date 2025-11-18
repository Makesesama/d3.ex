defmodule D3Ex.DataTest do
  use ExUnit.Case, async: true
  doctest D3Ex.Data

  describe "to_graph/1" do
    test "converts simple nodes and links" do
      nodes = [
        %{id: 1, name: "Alice"},
        %{id: 2, name: "Bob"}
      ]

      links = [
        %{source: 1, target: 2}
      ]

      result = D3Ex.Data.to_graph(nodes: nodes, links: links)

      assert result.nodes == [
               %{id: 1, label: "Alice"},
               %{id: 2, label: "Bob"}
             ]

      assert result.links == [%{source: 1, target: 2}]
    end

    test "maps custom node fields" do
      nodes = [
        %{user_id: 1, username: "alice", dept: "eng"},
        %{user_id: 2, username: "bob", dept: "sales"}
      ]

      links = []

      result =
        D3Ex.Data.to_graph(
          nodes: nodes,
          links: links,
          node_id: :user_id,
          node_label: :username,
          node_group: :dept
        )

      assert result.nodes == [
               %{id: 1, label: "alice", group: "eng"},
               %{id: 2, label: "bob", group: "sales"}
             ]
    end

    test "maps custom link fields" do
      nodes = [%{id: 1, name: "A"}, %{id: 2, name: "B"}]

      links = [
        %{from: 1, to: 2, weight: 5}
      ]

      result =
        D3Ex.Data.to_graph(
          nodes: nodes,
          links: links,
          link_source: :from,
          link_target: :to
        )

      assert result.links == [%{source: 1, target: 2, weight: 5}]
    end

    test "preserves extra node attributes" do
      nodes = [
        %{id: 1, name: "Alice", email: "alice@test.com", score: 95}
      ]

      result = D3Ex.Data.to_graph(nodes: nodes, links: [])

      [node] = result.nodes
      assert node.email == "alice@test.com"
      assert node.score == 95
    end
  end

  describe "filter/2" do
    test "filters data based on predicate" do
      data = [
        %{name: "Alice", active: true},
        %{name: "Bob", active: false},
        %{name: "Charlie", active: true}
      ]

      result = D3Ex.Data.filter(data, & &1.active)

      assert length(result) == 2
      assert Enum.all?(result, & &1.active)
    end

    test "chains multiple filters" do
      data = [
        %{name: "Alice", active: true, score: 90},
        %{name: "Bob", active: true, score: 50},
        %{name: "Charlie", active: false, score: 95}
      ]

      result =
        data
        |> D3Ex.Data.filter(& &1.active)
        |> D3Ex.Data.filter(&(&1.score > 80))

      assert result == [%{name: "Alice", active: true, score: 90}]
    end
  end

  describe "group_by/2" do
    test "groups by field" do
      data = [
        %{name: "Alice", region: "North"},
        %{name: "Bob", region: "South"},
        %{name: "Charlie", region: "North"}
      ]

      result = D3Ex.Data.group_by(data, :region)

      assert map_size(result) == 2
      assert length(result["North"]) == 2
      assert length(result["South"]) == 1
    end

    test "groups by function" do
      data = [
        %{name: "Alice", score: 95},
        %{name: "Bob", score: 55},
        %{name: "Charlie", score: 85}
      ]

      result =
        D3Ex.Data.group_by(data, fn item ->
          if item.score >= 80, do: :high, else: :low
        end)

      assert map_size(result) == 2
      assert length(result[:high]) == 2
      assert length(result[:low]) == 1
    end
  end

  describe "aggregate/3" do
    setup do
      data = [
        %{category: "A", amount: 100},
        %{category: "A", amount: 150},
        %{category: "B", amount: 200}
      ]

      grouped = D3Ex.Data.group_by(data, :category)
      %{grouped: grouped}
    end

    test "sums values", %{grouped: grouped} do
      result = D3Ex.Data.aggregate(grouped, :sum, :amount)

      a_result = Enum.find(result, &(&1.category == "A"))
      assert a_result.sum_amount == 250

      b_result = Enum.find(result, &(&1.category == "B"))
      assert b_result.sum_amount == 200
    end

    test "averages values", %{grouped: grouped} do
      result = D3Ex.Data.aggregate(grouped, :avg, :amount)

      a_result = Enum.find(result, &(&1.category == "A"))
      assert a_result.avg_amount == 125.0

      b_result = Enum.find(result, &(&1.category == "B"))
      assert b_result.avg_amount == 200.0
    end

    test "counts records", %{grouped: grouped} do
      result = D3Ex.Data.aggregate(grouped, :count, :amount)

      assert Enum.all?(result, &Map.has_key?(&1, :count))

      a_result = Enum.find(result, &(&1.category == "A"))
      assert a_result.count == 2
    end

    test "finds min and max", %{grouped: grouped} do
      result_min = D3Ex.Data.aggregate(grouped, :min, :amount)
      result_max = D3Ex.Data.aggregate(grouped, :max, :amount)

      a_min = Enum.find(result_min, &(&1.category == "A"))
      assert a_min.min_amount == 100

      a_max = Enum.find(result_max, &(&1.category == "A"))
      assert a_max.max_amount == 150
    end
  end

  describe "sort_by/3" do
    test "sorts ascending" do
      data = [
        %{name: "Charlie", score: 70},
        %{name: "Alice", score: 90},
        %{name: "Bob", score: 80}
      ]

      result = D3Ex.Data.sort_by(data, :score, :asc)

      assert Enum.map(result, & &1.score) == [70, 80, 90]
    end

    test "sorts descending" do
      data = [
        %{name: "Charlie", score: 70},
        %{name: "Alice", score: 90},
        %{name: "Bob", score: 80}
      ]

      result = D3Ex.Data.sort_by(data, :score, :desc)

      assert Enum.map(result, & &1.score) == [90, 80, 70]
    end
  end

  describe "limit/2" do
    test "limits results to N items" do
      data = Enum.map(1..100, &%{id: &1})

      result = D3Ex.Data.limit(data, 10)

      assert length(result) == 10
    end

    test "works with full pipeline" do
      data = Enum.map(1..100, &%{id: &1, value: :rand.uniform(100)})

      result =
        data
        |> D3Ex.Data.sort_by(:value, :desc)
        |> D3Ex.Data.limit(5)

      assert length(result) == 5
    end
  end

  describe "add_field/3" do
    test "adds computed field with 2-arity function" do
      data = [
        %{name: "Alice", amount: 100},
        %{name: "Bob", amount: 200}
      ]

      result =
        D3Ex.Data.add_field(data, :percentage, fn item, all_data ->
          total = Enum.sum(Enum.map(all_data, & &1.amount))
          item.amount / total * 100
        end)

      alice = Enum.find(result, &(&1.name == "Alice"))
      assert_in_delta alice.percentage, 33.33, 0.01
    end

    test "adds rank field with 3-arity function" do
      data = [
        %{name: "Alice"},
        %{name: "Bob"},
        %{name: "Charlie"}
      ]

      result =
        D3Ex.Data.add_field(data, :rank, fn _item, _all, index ->
          index + 1
        end)

      assert Enum.map(result, & &1.rank) == [1, 2, 3]
    end
  end

  describe "pivot/2" do
    test "pivots long to wide format" do
      data = [
        %{region: "North", month: "Jan", amount: 100},
        %{region: "North", month: "Feb", amount: 150},
        %{region: "South", month: "Jan", amount: 80},
        %{region: "South", month: "Feb", amount: 90}
      ]

      result =
        D3Ex.Data.pivot(data,
          index: :region,
          columns: :month,
          values: :amount
        )

      north = Enum.find(result, &(&1.region == "North"))
      assert north["Jan"] == 100
      assert north["Feb"] == 150

      south = Enum.find(result, &(&1.region == "South"))
      assert south["Jan"] == 80
      assert south["Feb"] == 90
    end
  end

  describe "sample/2" do
    test "samples N random items" do
      data = Enum.map(1..100, &%{id: &1})

      result = D3Ex.Data.sample(data, 10)

      assert length(result) == 10
      assert Enum.all?(result, &Map.has_key?(&1, :id))
    end
  end

  describe "full pipeline integration" do
    test "complex data transformation pipeline" do
      # Simulate sales data
      sales =
        for category <- ["Electronics", "Books", "Clothing"],
            region <- ["North", "South"],
            _i <- 1..5 do
          %{
            category: category,
            region: region,
            amount: :rand.uniform(1000),
            active: :rand.uniform() > 0.2
          }
        end

      # Transform with pipeline
      result =
        sales
        |> D3Ex.Data.filter(& &1.active)
        |> D3Ex.Data.group_by(:category)
        |> D3Ex.Data.aggregate(:sum, :amount)
        |> D3Ex.Data.sort_by(:sum_amount, :desc)
        |> D3Ex.Data.limit(2)
        |> D3Ex.Data.add_field(:rank, fn _item, _all, index -> index + 1 end)

      assert length(result) == 2
      assert Enum.all?(result, &Map.has_key?(&1, :sum_amount))
      assert Enum.all?(result, &Map.has_key?(&1, :rank))
      assert Enum.map(result, & &1.rank) == [1, 2]
    end
  end
end
