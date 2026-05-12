defmodule D3ExDemoWeb.StreamLive do
  use D3ExDemoWeb, :live_view

  import D3Ex.Components.StreamChart

  # Phoenix prunes positive limits from the back (newest) and negative limits
  # from the front (oldest). For a rolling window of "keep the last N" we
  # need a negative limit.
  @window_size -200
  @tick_ms 250

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@tick_ms, self(), :tick)
    end

    socket =
      socket
      |> assign(:page_title, "Phoenix stream/3 bridge")
      |> assign(:tick_count, 0)
      |> stream_configure(:points, dom_id: &"pt-#{&1.t}")
      |> stream(:points, seed())

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    t = System.system_time(:millisecond)
    point = %{t: t, y: :math.sin(t / 1000)}

    {:noreply,
     socket
     |> stream_insert(:points, point, limit: @window_size)
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
        <h1 class="text-2xl font-semibold">Phoenix <code>stream/3</code> bridge</h1>
        <p class="text-sm text-base-content/70">
          Every 250&nbsp;ms the server calls
          <code>stream_insert(socket, :points, p, limit: -200)</code>. The chart
          is fed by a hidden <code>phx-update="stream"</code> element that
          <code>D3Stream</code> observes with a <code>MutationObserver</code>.
          (Negative limit = keep the last N items; positive would prune your
          new appends and freeze the chart at 200.)
        </p>
        <p class="text-sm text-base-content/70">
          Server memory is capped at 200 items; the WebSocket frame is one
          stream diff per tick; reconnecting after a drop restores the chart
          from the server-side stream snapshot — none of which we had to
          implement ourselves.
        </p>
      </header>

      <.stream_chart
        id="ticks"
        stream={@streams.points}
        x_key={:t}
        y_key={:y}
        renderer="line"
        width={700}
        height={360}
        show_points={false}
        show_area={true}
        animation_duration={120}
      />

      <p class="text-sm text-base-content/60">
        Ticks: <strong>{@tick_count}</strong>
      </p>
    </div>
    """
  end

  defp seed do
    now = System.system_time(:millisecond)

    for i <- -29..0 do
      t = now + i * @tick_ms
      %{t: t, y: :math.sin(t / 1000)}
    end
  end
end
