defmodule D3Ex.Data do
  @moduledoc """
  Data transformation utilities for D3 visualizations.

  This module provides helper functions to transform raw data into formats
  suitable for D3 components. Focus on common data preparation patterns
  to make working with D3Ex more ergonomic.

  ## Philosophy

  Following the VegaLite.ex pattern, we abstract data transformation in Elixir
  and let JavaScript/D3 handle the rendering. This keeps the library maintainable
  and performant.

  ## Examples

      # Transform database records to graph structure
      graph_data =
        MyApp.Repo.all(User)
        |> D3Ex.Data.to_graph(
          nodes: &Function.identity/1,
          node_id: :id,
          node_label: :name,
          links_from: &MyApp.get_relationships/1,
          link_source: :from_id,
          link_target: :to_id
        )

      # Prepare aggregated bar chart data
      chart_data =
        raw_sales
        |> D3Ex.Data.filter(&(&1.active))
        |> D3Ex.Data.group_by(:category)
        |> D3Ex.Data.aggregate(:sum, :revenue)
        |> D3Ex.Data.sort_by(:revenue, :desc)
        |> D3Ex.Data.limit(10)
  """

  @doc """
  Convert relational data to graph structure (nodes and links).

  ## Options

    * `:nodes` - List of node data or function to extract nodes
    * `:node_id` - Field to use as node ID (default: `:id`)
    * `:node_label` - Field to use as node label (default: `:name`)
    * `:node_group` - Field to use for grouping/coloring (optional)
    * `:links` - List of link data (required if not using `:links_from`)
    * `:links_from` - Function to extract links from nodes
    * `:link_source` - Field for link source ID (default: `:source`)
    * `:link_target` - Field for link target ID (default: `:target`)

  ## Examples

      # Simple case: separate nodes and links lists
      graph = D3Ex.Data.to_graph(
        nodes: users,
        links: relationships,
        node_id: :id,
        node_label: :name,
        link_source: :from_user_id,
        link_target: :to_user_id
      )

      # Complex case: extract links from nested data
      graph = D3Ex.Data.to_graph(
        nodes: users,
        node_id: :id,
        node_label: :name,
        node_group: :department,
        links_from: fn user -> user.reports_to end,
        link_source: :user_id,
        link_target: :manager_id
      )

  Returns a map with `:nodes` and `:links` keys.
  """
  def to_graph(opts) when is_list(opts) do
    node_id_key = opts[:node_id] || :id
    node_label_key = opts[:node_label] || :name
    node_group_key = opts[:node_group]

    # Extract nodes
    nodes =
      case opts[:nodes] do
        nodes when is_list(nodes) ->
          Enum.map(nodes, fn node ->
            base = %{
              id: Map.get(node, node_id_key),
              label: Map.get(node, node_label_key)
            }

            if node_group_key do
              Map.put(base, :group, Map.get(node, node_group_key))
            else
              base
            end
            |> Map.merge(Map.drop(node, [node_id_key, node_label_key, node_group_key]))
          end)

        nodes_fn when is_function(nodes_fn) ->
          nodes_fn.()
          |> Enum.map(fn node ->
            %{
              id: Map.get(node, node_id_key),
              label: Map.get(node, node_label_key)
            }
          end)
      end

    # Extract links
    links =
      cond do
        opts[:links] ->
          link_source_key = opts[:link_source] || :source
          link_target_key = opts[:link_target] || :target

          Enum.map(opts[:links], fn link ->
            %{
              source: Map.get(link, link_source_key),
              target: Map.get(link, link_target_key)
            }
            |> Map.merge(Map.drop(link, [link_source_key, link_target_key]))
          end)

        opts[:links_from] ->
          extract_links_from_nodes(nodes, opts)

        true ->
          []
      end

    %{nodes: nodes, links: links}
  end

  defp extract_links_from_nodes(nodes, opts) do
    links_from_fn = opts[:links_from]
    link_source_key = opts[:link_source] || :source
    link_target_key = opts[:link_target] || :target

    Enum.flat_map(nodes, fn node ->
      case links_from_fn.(node) do
        nil ->
          []

        [] ->
          []

        link when is_map(link) ->
          [normalize_link(link, link_source_key, link_target_key)]

        links when is_list(links) ->
          Enum.map(links, &normalize_link(&1, link_source_key, link_target_key))
      end
    end)
  end

  defp normalize_link(link, source_key, target_key) do
    %{
      source: Map.get(link, source_key),
      target: Map.get(link, target_key)
    }
    |> Map.merge(Map.drop(link, [source_key, target_key]))
  end

  @doc """
  Filter data based on predicate function.

  ## Examples

      data
      |> D3Ex.Data.filter(&(&1.active == true))
      |> D3Ex.Data.filter(&(&1.revenue > 1000))
  """
  def filter(data, predicate) when is_function(predicate) do
    Enum.filter(data, predicate)
  end

  @doc """
  Group data by field or function.

  Returns a map where keys are group values and values are lists of records.

  ## Examples

      # Group by field
      grouped = D3Ex.Data.group_by(sales, :region)
      # => %{"North" => [...], "South" => [...]}

      # Group by function
      grouped = D3Ex.Data.group_by(sales, fn sale ->
        if sale.amount > 1000, do: :high, else: :low
      end)
  """
  def group_by(data, field) when is_atom(field) do
    Enum.group_by(data, &Map.get(&1, field))
  end

  def group_by(data, fun) when is_function(fun) do
    Enum.group_by(data, fun)
  end

  @doc """
  Aggregate grouped data.

  ## Operations

    * `:sum` - Sum of field values
    * `:avg` - Average of field values
    * `:count` - Count of records
    * `:min` - Minimum field value
    * `:max` - Maximum field value
    * `:list` - List of field values
    * `{:percentile, n}` - Nth percentile

  ## Examples

      sales
      |> D3Ex.Data.group_by(:category)
      |> D3Ex.Data.aggregate(:sum, :revenue)
      # => [
      #   %{category: "Electronics", sum_revenue: 50000},
      #   %{category: "Books", sum_revenue: 20000}
      # ]

      sales
      |> D3Ex.Data.group_by(:region)
      |> D3Ex.Data.aggregate(:avg, :sale_amount)
  """
  def aggregate(grouped_data, operation, field) when is_map(grouped_data) do
    Enum.map(grouped_data, fn {group_key, records} ->
      aggregated_value = compute_aggregate(records, operation, field)
      field_name = aggregate_field_name(operation, field)

      # Determine the group field name
      group_field =
        case records do
          [first | _] ->
            # Try to find the field that has the group_key value
            Enum.find(Map.keys(first), fn key ->
              Map.get(first, key) == group_key
            end)

          [] ->
            :group
        end

      %{
        (group_field || :group) => group_key,
        field_name => aggregated_value,
        :count => length(records)
      }
    end)
  end

  defp compute_aggregate(records, :sum, field) do
    Enum.reduce(records, 0, fn record, acc ->
      acc + (Map.get(record, field) || 0)
    end)
  end

  defp compute_aggregate(records, :avg, field) do
    sum = compute_aggregate(records, :sum, field)
    if length(records) > 0, do: sum / length(records), else: 0
  end

  defp compute_aggregate(records, :count, _field) do
    length(records)
  end

  defp compute_aggregate(records, :min, field) do
    records
    |> Enum.map(&Map.get(&1, field))
    |> Enum.min(fn -> nil end)
  end

  defp compute_aggregate(records, :max, field) do
    records
    |> Enum.map(&Map.get(&1, field))
    |> Enum.max(fn -> nil end)
  end

  defp compute_aggregate(records, :list, field) do
    Enum.map(records, &Map.get(&1, field))
  end

  defp compute_aggregate(records, {:percentile, n}, field) when n >= 0 and n <= 100 do
    sorted = Enum.sort_by(records, &Map.get(&1, field))
    index = round(length(sorted) * n / 100)
    Enum.at(sorted, index) |> Map.get(field)
  end

  defp aggregate_field_name(:sum, field), do: :"sum_#{field}"
  defp aggregate_field_name(:avg, field), do: :"avg_#{field}"
  defp aggregate_field_name(:min, field), do: :"min_#{field}"
  defp aggregate_field_name(:max, field), do: :"max_#{field}"
  defp aggregate_field_name(:count, _field), do: :count
  defp aggregate_field_name(:list, field), do: :"list_#{field}"
  defp aggregate_field_name({:percentile, n}, field), do: :"p#{n}_#{field}"

  @doc """
  Sort data by field or function.

  ## Examples

      # Sort ascending
      D3Ex.Data.sort_by(data, :revenue, :asc)

      # Sort descending
      D3Ex.Data.sort_by(data, :revenue, :desc)

      # Sort by function
      D3Ex.Data.sort_by(data, fn item -> item.score * item.weight end)
  """
  def sort_by(data, field) when is_atom(field) do
    sort_by(data, field, :asc)
  end

  def sort_by(data, fun) when is_function(fun) do
    Enum.sort_by(data, fun)
  end

  def sort_by(data, field, direction) when is_atom(field) do
    sorted = Enum.sort_by(data, &Map.get(&1, field))

    case direction do
      :asc -> sorted
      :desc -> Enum.reverse(sorted)
    end
  end

  @doc """
  Limit results to first N items.

  ## Examples

      data
      |> D3Ex.Data.sort_by(:revenue, :desc)
      |> D3Ex.Data.limit(10)  # Top 10
  """
  def limit(data, n) when is_integer(n) and n > 0 do
    Enum.take(data, n)
  end

  @doc """
  Add a computed field to each record.

  ## Examples

      # Add percentage field
      data
      |> D3Ex.Data.add_field(:percentage, fn item, all_data ->
        total = Enum.sum(Enum.map(all_data, & &1.amount))
        item.amount / total * 100
      end)

      # Add rank field
      data
      |> D3Ex.Data.sort_by(:revenue, :desc)
      |> D3Ex.Data.add_field(:rank, fn _item, _all, index ->
        index + 1
      end)
  """
  def add_field(data, field_name, value_fn) when is_function(value_fn, 2) do
    Enum.map(data, fn item ->
      Map.put(item, field_name, value_fn.(item, data))
    end)
  end

  def add_field(data, field_name, value_fn) when is_function(value_fn, 3) do
    data
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      Map.put(item, field_name, value_fn.(item, data, index))
    end)
  end

  @doc """
  Pivot data from long to wide format.

  ## Examples

      # Long format
      sales = [
        %{region: "North", month: "Jan", amount: 100},
        %{region: "North", month: "Feb", amount: 150},
        %{region: "South", month: "Jan", amount: 80}
      ]

      # Pivot to wide format
      pivoted = D3Ex.Data.pivot(sales,
        index: :region,
        columns: :month,
        values: :amount
      )

      # Result:
      [
        %{region: "North", Jan: 100, Feb: 150},
        %{region: "South", Jan: 80, Feb: nil}
      ]
  """
  def pivot(data, opts) do
    index_field = opts[:index]
    column_field = opts[:columns]
    value_field = opts[:values]

    # Get unique column values
    column_values =
      data
      |> Enum.map(&Map.get(&1, column_field))
      |> Enum.uniq()

    # Group by index field
    grouped = Enum.group_by(data, &Map.get(&1, index_field))

    # Build pivoted records
    Enum.map(grouped, fn {index_value, records} ->
      base = %{index_field => index_value}

      values =
        Enum.reduce(column_values, %{}, fn col_val, acc ->
          matching_record = Enum.find(records, &(Map.get(&1, column_field) == col_val))
          value = if matching_record, do: Map.get(matching_record, value_field), else: nil
          Map.put(acc, col_val, value)
        end)

      Map.merge(base, values)
    end)
  end

  @doc """
  Sample N random items from data.

  ## Examples

      D3Ex.Data.sample(large_dataset, 100)  # Random sample of 100 items
  """
  def sample(data, n) when is_integer(n) and n > 0 do
    Enum.take_random(data, n)
  end
end
