defmodule D3ExDemoWeb.DashboardLive do
  use D3ExDemoWeb, :live_view

  import D3ExDemoWeb.Components.Charts.BarChart
  import D3ExDemoWeb.Components.Charts.LineChart
  import D3ExDemoWeb.Components.Charts.NetworkGraph

  @sales [
    %{month: "Jan", sales: 12_000},
    %{month: "Feb", sales: 14_500},
    %{month: "Mar", sales: 13_200},
    %{month: "Apr", sales: 18_100},
    %{month: "May", sales: 16_300},
    %{month: "Jun", sales: 19_900}
  ]

  @nodes [
    %{id: "n1", label: "Service A", group: "api"},
    %{id: "n2", label: "Service B", group: "api"},
    %{id: "n3", label: "Postgres", group: "db"},
    %{id: "n4", label: "Redis", group: "db"},
    %{id: "n5", label: "Worker", group: "job"}
  ]

  @links [
    %{source: "n1", target: "n3"},
    %{source: "n1", target: "n4"},
    %{source: "n2", target: "n3"},
    %{source: "n5", target: "n3"},
    %{source: "n5", target: "n4"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:sales_seed, @sales)
     |> assign(:metrics_seed, metrics_seed())
     |> assign(:nodes_seed, @nodes)
     |> assign(:links_seed, @links)}
  end

  @impl true
  def handle_info(:tick, socket) do
    now = System.system_time(:millisecond)

    metrics_delta = [
      %{t: now, value: 50 + :rand.uniform(40), metric: "cpu"},
      %{t: now, value: 30 + :rand.uniform(20), metric: "memory"}
    ]

    sales_patch =
      @sales
      |> Enum.take_random(2)
      |> Enum.map(fn item ->
        %{key: item.month, changes: %{sales: item.sales + :rand.uniform(2000) - 1000}}
      end)

    {:noreply,
     socket
     |> D3Ex.Live.append("d-metrics", metrics_delta)
     |> D3Ex.Live.patch("d-sales", sales_patch)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl px-6 py-8 space-y-6">
      <header class="space-y-1">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:underline">
          ← home
        </.link>
        <h1 class="text-2xl font-semibold">Dashboard</h1>
        <p class="text-sm text-base-content/70">
          One PubSub tick (1&nbsp;s) drives all three charts. Each chart receives
          its own id-scoped delta — the network graph stays untouched, the line
          chart gets an <code>append</code>, the bar chart gets a 2-row
          <code>patch</code>.
        </p>
      </header>

      <div class="grid gap-6 lg:grid-cols-2">
        <section class="space-y-2">
          <h2 class="text-lg font-medium">Monthly sales</h2>
          <.bar_chart
            id="d-sales"
            initial_data={@sales_seed}
            x_key={:month}
            y_key={:sales}
            width={520}
            height={320}
            animation_duration={400}
          />
        </section>

        <section class="space-y-2">
          <h2 class="text-lg font-medium">Live metrics</h2>
          <.line_chart
            id="d-metrics"
            initial_data={@metrics_seed}
            x_key={:t}
            y_key={:value}
            series_key={:metric}
            width={520}
            height={320}
            show_points={false}
            show_area={true}
            animation_duration={250}
          />
        </section>

        <section class="space-y-2 lg:col-span-2">
          <h2 class="text-lg font-medium">Service graph</h2>
          <.network_graph
            id="d-graph"
            initial_nodes={@nodes_seed}
            initial_links={@links_seed}
            width={1000}
            height={400}
            charge_strength={-300}
            link_distance={100}
          />
        </section>
      </div>
    </div>
    """
  end

  defp metrics_seed do
    base = System.system_time(:millisecond) - 60 * 1_000

    for i <- 0..60, metric <- ["cpu", "memory"] do
      %{
        t: base + i * 1_000,
        value:
          case metric do
            "cpu" -> 50 + :rand.uniform(40)
            "memory" -> 30 + :rand.uniform(20)
          end,
        metric: metric
      }
    end
  end
end
