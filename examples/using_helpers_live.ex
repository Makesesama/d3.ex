defmodule D3Ex.Examples.UsingHelpersLive do
  @moduledoc """
  Example LiveView demonstrating D3Ex.Data and D3Ex.Config helpers.

  This example shows how to use the new helper modules to:
  - Transform data easily
  - Build configurations ergonomically
  - Compose configurations
  - Follow the VegaLite.ex pattern
  """

  use Phoenix.LiveView
  import D3Ex.Components.{NetworkGraph, BarChart, LineChart}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:raw_sales, raw_sales_data())
     |> assign(:raw_users, raw_users_data())
     |> assign(:selected_node, nil)
     |> prepare_all_charts()}
  end

  @impl true
  def handle_event("node_selected", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_node, id)}
  end

  @impl true
  def handle_event("category_clicked", %{"category" => category}, socket) do
    IO.inspect(category, label: "Category clicked")
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8 space-y-8">
      <header>
        <h1 class="text-3xl font-bold mb-2">D3Ex Helpers Demo</h1>
        <p class="text-gray-600">
          Demonstrating D3Ex.Data and D3Ex.Config for ergonomic visualization building
        </p>
      </header>

      <!-- Example 1: Network Graph with Config Helpers -->
      <section class="border rounded-lg p-6 bg-white">
        <h2 class="text-2xl font-semibold mb-4">1. Network Graph with Config Helpers</h2>
        <p class="text-sm text-gray-600 mb-4">
          Using D3Ex.Config.network_graph() and D3Ex.Data.to_graph()
        </p>

        <.network_graph
          id="user-network"
          nodes={@user_graph.nodes}
          links={@user_graph.links}
          selected={@selected_node}
          on_select="node_selected"
          config={@network_config}
        />

        <div class="mt-4 p-4 bg-gray-50 rounded">
          <h3 class="font-semibold mb-2">Code:</h3>
          <pre class="text-xs overflow-x-auto"><code>
    # Transform data
    graph = D3Ex.Data.to_graph(
    nodes: users,
    node_id: :id,
    node_label: :name,
    node_group: :department,
    links: relationships,
    link_source: :from_id,
    link_target: :to_id
    )

    # Build config
    config = D3Ex.Config.network_graph(
    size: {900, 500},
    forces: [charge: -400, link: [distance: 120]],
    theme: :dark,
    node_radius: 12
    )
          </code></pre>
        </div>
      </section>

      <!-- Example 2: Bar Chart with Data Pipeline -->
      <section class="border rounded-lg p-6 bg-white">
        <h2 class="text-2xl font-semibold mb-4">2. Bar Chart with Data Pipeline</h2>
        <p class="text-sm text-gray-600 mb-4">
          Using D3Ex.Data pipeline to transform and aggregate data
        </p>

        <.bar_chart
          id="top-categories"
          data={@top_categories}
          x_key={:category}
          y_key={:sum_revenue}
          config={@bar_config}
          on_bar_click="category_clicked"
        />

        <div class="mt-4 p-4 bg-gray-50 rounded">
          <h3 class="font-semibold mb-2">Code:</h3>
          <pre class="text-xs overflow-x-auto"><code>
    # Data transformation pipeline
    top_categories =
    raw_sales
    |> D3Ex.Data.filter(&(&1.active))
    |> D3Ex.Data.group_by(:category)
    |> D3Ex.Data.aggregate(:sum, :revenue)
    |> D3Ex.Data.sort_by(:sum_revenue, :desc)
    |> D3Ex.Data.limit(10)

    # Config with helpers
    config = D3Ex.Config.bar_chart(
    size: {700, 400},
    theme: :corporate,
    bar_padding: 0.2,
    show_values: true
    )
          </code></pre>
        </div>
      </section>

      <!-- Example 3: Line Chart with Computed Fields -->
      <section class="border rounded-lg p-6 bg-white">
        <h2 class="text-2xl font-semibold mb-4">3. Line Chart with Computed Fields</h2>
        <p class="text-sm text-gray-600 mb-4">
          Using D3Ex.Data.add_field() to compute percentages and moving averages
        </p>

        <.line_chart
          id="sales-trends"
          data={@sales_with_metrics}
          x_key={:month}
          y_key={:revenue}
          config={@line_config}
        />

        <div class="mt-4 p-4 bg-gray-50 rounded">
          <h3 class="font-semibold mb-2">Code:</h3>
          <pre class="text-xs overflow-x-auto"><code>
    # Add computed fields
    sales_with_metrics =
    monthly_sales
    |> D3Ex.Data.add_field(:percentage, fn item, all_data ->
    total = Enum.sum(Enum.map(all_data, & &1.revenue))
    item.revenue / total * 100
    end)
    |> D3Ex.Data.add_field(:rank, fn _item, _all, index ->
    index + 1
    end)

    # Config composition
    config =
    D3Ex.Config.theme(:vibrant)
    |> D3Ex.Config.merge(D3Ex.Config.line_chart(
    size: {700, 300},
    curve: :monotone,
    show_area: true
    ))
          </code></pre>
        </div>
      </section>

      <!-- Stats Section -->
      <section class="border rounded-lg p-6 bg-gray-100">
        <h2 class="text-xl font-semibold mb-4">Dataset Statistics</h2>
        <div class="grid grid-cols-3 gap-4">
          <div>
            <div class="text-sm text-gray-600">Total Sales Records</div>
            <div class="text-2xl font-bold"><%= length(@raw_sales) %></div>
          </div>
          <div>
            <div class="text-sm text-gray-600">Active Categories</div>
            <div class="text-2xl font-bold"><%= length(@top_categories) %></div>
          </div>
          <div>
            <div class="text-sm text-gray-600">Users in Network</div>
            <div class="text-2xl font-bold"><%= length(@user_graph.nodes) %></div>
          </div>
        </div>
      </section>
    </div>
    """
  end

  ## Private Functions

  defp prepare_all_charts(socket) do
    socket
    |> prepare_network_graph()
    |> prepare_top_categories()
    |> prepare_sales_trends()
  end

  defp prepare_network_graph(socket) do
    # Transform users and relationships to graph structure
    graph =
      D3Ex.Data.to_graph(
        nodes: socket.assigns.raw_users,
        node_id: :id,
        node_label: :name,
        node_group: :department,
        links: user_relationships(),
        link_source: :from_id,
        link_target: :to_id
      )

    # Build configuration using helpers
    config =
      D3Ex.Config.network_graph(
        size: {900, 500},
        forces: [
          charge: -400,
          link: [distance: 120, strength: 1],
          collision: 18
        ],
        theme: :dark,
        node_radius: 12,
        interactions: [drag: true, zoom: true, select: true]
      )

    socket
    |> assign(:user_graph, graph)
    |> assign(:network_config, config)
  end

  defp prepare_top_categories(socket) do
    # Use data transformation pipeline
    top_categories =
      socket.assigns.raw_sales
      |> D3Ex.Data.filter(& &1.active)
      |> D3Ex.Data.group_by(:category)
      |> D3Ex.Data.aggregate(:sum, :revenue)
      |> D3Ex.Data.sort_by(:sum_revenue, :desc)
      |> D3Ex.Data.limit(10)
      |> D3Ex.Data.add_field(:percentage, fn item, all_data ->
        total = Enum.sum(Enum.map(all_data, & &1.sum_revenue))
        Float.round(item.sum_revenue / total * 100, 1)
      end)

    # Build bar chart config
    config =
      D3Ex.Config.bar_chart(
        size: {700, 400},
        theme: :corporate,
        bar_padding: 0.2,
        show_values: true,
        animation_duration: 500
      )

    socket
    |> assign(:top_categories, top_categories)
    |> assign(:bar_config, config)
  end

  defp prepare_sales_trends(socket) do
    # Monthly sales with computed metrics
    monthly_sales = generate_monthly_sales()

    sales_with_metrics =
      monthly_sales
      |> D3Ex.Data.add_field(:percentage, fn item, all_data ->
        total = Enum.sum(Enum.map(all_data, & &1.revenue))
        Float.round(item.revenue / total * 100, 1)
      end)
      |> D3Ex.Data.add_field(:rank, fn _item, _all, index ->
        index + 1
      end)

    # Compose configuration
    config =
      D3Ex.Config.theme(:vibrant)
      |> D3Ex.Config.merge(
        D3Ex.Config.line_chart(
          size: {700, 300},
          curve: :monotone,
          show_area: true,
          show_points: true
        )
      )

    socket
    |> assign(:sales_with_metrics, sales_with_metrics)
    |> assign(:line_config, config)
  end

  ## Sample Data Generators

  defp raw_sales_data do
    categories = ["Electronics", "Books", "Clothing", "Home", "Sports", "Toys", "Food"]
    regions = ["North", "South", "East", "West"]

    for category <- categories,
        region <- regions,
        _i <- 1..10 do
      %{
        id: :crypto.strong_rand_bytes(8) |> Base.encode16(),
        category: category,
        region: region,
        revenue: :rand.uniform(10000),
        active: :rand.uniform() > 0.1
      }
    end
  end

  defp raw_users_data do
    departments = ["Engineering", "Sales", "Marketing", "Support", "HR"]

    for i <- 1..20 do
      %{
        id: to_string(i),
        name: "User #{i}",
        department: Enum.random(departments),
        value: :rand.uniform(100)
      }
    end
  end

  defp user_relationships do
    for i <- 1..20, j <- 1..20, i != j, :rand.uniform() > 0.85 do
      %{
        from_id: to_string(i),
        to_id: to_string(j),
        type: Enum.random(["reports_to", "collaborates", "mentors"])
      }
    end
  end

  defp generate_monthly_sales do
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    Enum.map(months, fn month ->
      %{
        month: month,
        revenue: 10000 + :rand.uniform(5000)
      }
    end)
  end
end
