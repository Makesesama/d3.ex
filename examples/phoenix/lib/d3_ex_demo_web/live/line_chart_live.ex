defmodule D3ExDemoWeb.LineChartLive do
  use D3ExDemoWeb, :live_view

  import D3ExDemoWeb.Components.Charts.LineChart

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(500, self(), :tick)
    end

    {:ok,
     socket
     |> assign(:page_title, "Streaming line chart")
     |> assign(:initial_data, seed())
     |> assign(:tick_count, 0)}
  end

  @impl true
  def handle_info(:tick, socket) do
    now = System.system_time(:millisecond)

    new_points = [
      %{t: now, value: 50 + :rand.uniform(40), metric: "cpu"},
      %{t: now, value: 30 + :rand.uniform(20), metric: "memory"}
    ]

    {:noreply,
     socket
     |> D3Ex.Live.append("metrics", new_points)
     |> update(:tick_count, &(&1 + 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl px-6 py-8 space-y-6">
      <header class="space-y-1">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:underline">
          ← home
        </.link>
        <h1 class="text-2xl font-semibold">Streaming line chart</h1>
        <p class="text-sm text-base-content/70">
          Every 500&nbsp;ms the server pushes <code>D3Ex.Live.append/3</code>
          with two new points. The WebSocket frame for each tick is ~120 bytes,
          regardless of how many points are already on the chart.
        </p>
      </header>

      <.line_chart
        id="metrics"
        initial_data={@initial_data}
        x_key={:t}
        y_key={:value}
        series_key={:metric}
        width={700}
        height={360}
        show_points={false}
        show_area={true}
        animation_duration={250}
      />

      <p class="text-sm text-base-content/60">
        Ticks: <strong>{@tick_count}</strong>
      </p>
    </div>
    """
  end

  defp seed do
    base = System.system_time(:millisecond) - 60 * 500

    for i <- 0..60, metric <- ["cpu", "memory"] do
      %{
        t: base + i * 500,
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
