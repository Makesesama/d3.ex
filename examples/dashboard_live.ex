defmodule D3Ex.Examples.DashboardLive do
  @moduledoc """
  Example dashboard showing multiple D3 charts with real-time updates.

  Demonstrates:
  - Multiple chart types on one page
  - Coordinated updates across charts
  - Real-time data streaming
  - Efficient state management
  """

  use Phoenix.LiveView
  import D3Ex.Components.{NetworkGraph, BarChart, LineChart}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Simulate real-time updates
      :timer.send_interval(2000, self(), :update_metrics)
    end

    {:ok,
     socket
     |> assign(:page_title, "Analytics Dashboard")
     |> assign(:selected_metric, nil)
     |> assign_initial_data()}
  end

  @impl true
  def handle_info(:update_metrics, socket) do
    # Simulate new data arriving
    new_data_point = generate_metric_point()

    {:noreply,
     socket
     |> update(:time_series_data, &add_time_series_point(&1, new_data_point))
     |> update(:sales_data, &update_sales_data/1)
     |> push_event("metrics:updated", %{timestamp: DateTime.utc_now()})}
  end

  @impl true
  def handle_event("metric_selected", %{"metric" => metric}, socket) do
    {:noreply,
     socket
     |> assign(:selected_metric, metric)
     |> update_related_visualizations(metric)}
  end

  @impl true
  def handle_event("bar_clicked", %{"month" => month, "sales" => sales}, socket) do
    # When a bar is clicked, filter the network graph to show related entities
    {:noreply,
     socket
     |> assign(:selected_month, month)
     |> filter_network_by_month(month)}
  end

  @impl true
  def handle_event("node_selected", %{"id" => id}, socket) do
    # When a node is selected, highlight related data in charts
    {:noreply,
     socket
     |> assign(:selected_node, id)
     |> push_event("charts:highlight", %{entity_id: id})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 p-6">
      <div class="max-w-7xl mx-auto">
        <header class="mb-8">
          <h1 class="text-4xl font-bold text-gray-800">Analytics Dashboard</h1>
          <p class="text-gray-600 mt-2">Real-time metrics with D3Ex visualizations</p>
        </header>

        <!-- Top metrics cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div class="bg-white rounded-lg shadow p-6">
            <div class="text-sm text-gray-500">Total Sales</div>
            <div class="text-3xl font-bold text-gray-800">$<%= format_number(@total_sales) %></div>
            <div class="text-sm text-green-600">+12.5% from last month</div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="text-sm text-gray-500">Active Users</div>
            <div class="text-3xl font-bold text-gray-800"><%= @active_users %></div>
            <div class="text-sm text-green-600">+8.2% from last week</div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="text-sm text-gray-500">Network Nodes</div>
            <div class="text-3xl font-bold text-gray-800"><%= length(@network_nodes) %></div>
            <div class="text-sm text-gray-600"><%= length(@network_links) %> connections</div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="text-sm text-gray-500">Selected</div>
            <div class="text-lg font-semibold text-gray-800">
              <%= @selected_metric || @selected_node || "None" %>
            </div>
          </div>
        </div>

        <!-- Main dashboard grid -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Sales Bar Chart -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">Monthly Sales</h2>
            <.bar_chart
              id="sales-chart"
              data={@sales_data}
              x_key={:month}
              y_key={:sales}
              on_bar_click="bar_clicked"
              width={500}
              height={300}
              animation_duration={500}
            />
          </div>

          <!-- Time Series Line Chart -->
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">Real-time Metrics</h2>
            <.line_chart
              id="metrics-chart"
              data={@time_series_data}
              x_key={:timestamp}
              y_key={:value}
              series_key={:metric}
              width={500}
              height={300}
              show_points={false}
              show_area={true}
            />
          </div>

          <!-- Network Graph -->
          <div class="bg-white rounded-lg shadow p-6 lg:col-span-2">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">Entity Relationships</h2>
            <.network_graph
              id="entity-graph"
              nodes={@network_nodes}
              links={@network_links}
              selected={@selected_node}
              on_select="node_selected"
              width={1000}
              height={400}
              charge_strength={-300}
              link_distance={80}
            />
          </div>
        </div>

        <!-- Footer info -->
        <div class="mt-6 bg-white rounded-lg shadow p-4">
          <div class="text-sm text-gray-600">
            <strong>Live Updates:</strong> Charts update automatically every 2 seconds.
            Click on bars, points, or nodes to see coordinated interactions.
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private functions

  defp assign_initial_data(socket) do
    socket
    |> assign(:total_sales, 125_430)
    |> assign(:active_users, 1_247)
    |> assign(:selected_month, nil)
    |> assign(:selected_node, nil)
    |> assign(:sales_data, initial_sales_data())
    |> assign(:time_series_data, initial_time_series_data())
    |> assign(:network_nodes, initial_network_nodes())
    |> assign(:network_links, initial_network_links())
  end

  defp initial_sales_data do
    [
      %{month: "Jan", sales: 10_000, region: "North"},
      %{month: "Feb", sales: 12_500, region: "North"},
      %{month: "Mar", sales: 11_200, region: "North"},
      %{month: "Apr", sales: 15_800, region: "North"},
      %{month: "May", sales: 14_300, region: "North"},
      %{month: "Jun", sales: 17_900, region: "North"}
    ]
  end

  defp initial_time_series_data do
    base_time = DateTime.utc_now() |> DateTime.add(-60, :second)

    for i <- 0..60 do
      timestamp = DateTime.add(base_time, i, :second)

      [
        %{
          timestamp: DateTime.to_iso8601(timestamp),
          value: 50 + :rand.uniform(30),
          metric: "cpu"
        },
        %{
          timestamp: DateTime.to_iso8601(timestamp),
          value: 30 + :rand.uniform(20),
          metric: "memory"
        }
      ]
    end
    |> List.flatten()
  end

  defp initial_network_nodes do
    [
      %{id: "customer_1", label: "Customer A", group: "customer"},
      %{id: "customer_2", label: "Customer B", group: "customer"},
      %{id: "customer_3", label: "Customer C", group: "customer"},
      %{id: "product_1", label: "Product X", group: "product"},
      %{id: "product_2", label: "Product Y", group: "product"},
      %{id: "product_3", label: "Product Z", group: "product"},
      %{id: "store_1", label: "Store North", group: "store"},
      %{id: "store_2", label: "Store South", group: "store"}
    ]
  end

  defp initial_network_links do
    [
      %{source: "customer_1", target: "product_1"},
      %{source: "customer_1", target: "product_2"},
      %{source: "customer_2", target: "product_2"},
      %{source: "customer_2", target: "product_3"},
      %{source: "customer_3", target: "product_1"},
      %{source: "product_1", target: "store_1"},
      %{source: "product_2", target: "store_1"},
      %{source: "product_3", target: "store_2"},
      %{source: "customer_3", target: "store_2"}
    ]
  end

  defp generate_metric_point do
    %{
      timestamp: DateTime.to_iso8601(DateTime.utc_now()),
      cpu: 50 + :rand.uniform(30),
      memory: 30 + :rand.uniform(20)
    }
  end

  defp add_time_series_point(existing_data, new_point) do
    new_entries = [
      %{
        timestamp: new_point.timestamp,
        value: new_point.cpu,
        metric: "cpu"
      },
      %{
        timestamp: new_point.timestamp,
        value: new_point.memory,
        metric: "memory"
      }
    ]

    # Keep only last 60 seconds of data
    all_data = existing_data ++ new_entries

    if length(all_data) > 120 do
      Enum.drop(all_data, 2)
    else
      all_data
    end
  end

  defp update_sales_data(existing_data) do
    # Randomly update one month's sales
    Enum.map(existing_data, fn item ->
      if :rand.uniform(10) > 8 do
        %{item | sales: item.sales + :rand.uniform(1000)}
      else
        item
      end
    end)
  end

  defp update_related_visualizations(socket, metric) do
    # Filter or highlight related data based on selected metric
    # This is where you'd implement cross-chart coordination
    socket
  end

  defp filter_network_by_month(socket, month) do
    # Filter network graph based on selected month
    # In a real app, this would query filtered data
    socket
  end

  defp format_number(num) when is_integer(num) do
    num
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end
end
