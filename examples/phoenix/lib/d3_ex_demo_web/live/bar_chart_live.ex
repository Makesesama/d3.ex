defmodule D3ExDemoWeb.BarChartLive do
  use D3ExDemoWeb, :live_view

  import D3ExDemoWeb.Components.Charts.BarChart

  @initial_data [
    %{month: "Jan", sales: 12_000},
    %{month: "Feb", sales: 14_500},
    %{month: "Mar", sales: 13_200},
    %{month: "Apr", sales: 18_100},
    %{month: "May", sales: 16_300},
    %{month: "Jun", sales: 19_900}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Bar chart",
       initial_data: @initial_data,
       last_action: nil
     )}
  end

  @impl true
  def handle_event("randomize", _params, socket) do
    randomized =
      Enum.map(@initial_data, fn item ->
        %{item | sales: item.sales + :rand.uniform(8_000) - 4_000}
      end)

    {:noreply,
     socket
     |> D3Ex.Live.set_data("sales", randomized)
     |> assign(:last_action, "set_data — replaced the whole dataset")}
  end

  @impl true
  def handle_event("patch_feb", _params, socket) do
    {:noreply,
     socket
     |> D3Ex.Live.patch("sales", [
       %{key: "Feb", changes: %{sales: 30_000}}
     ])
     |> assign(:last_action, "patch — only Feb was sent")}
  end

  @impl true
  def handle_event("remove_jan", _params, socket) do
    {:noreply,
     socket
     |> D3Ex.Live.remove("sales", ["Jan"])
     |> assign(:last_action, "remove — Jan was dropped")}
  end

  @impl true
  def handle_event("bar_clicked", %{"month" => month}, socket) do
    {:noreply, assign(socket, :last_action, "clicked bar: #{month}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl px-6 py-8 space-y-6">
      <header class="space-y-1">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:underline">
          ← home
        </.link>
        <h1 class="text-2xl font-semibold">Bar chart</h1>
        <p class="text-sm text-base-content/70">
          Each button calls a different <code>D3Ex.Live</code> helper. The chart
          never re-renders server-side — open the WS frames panel to see the
          payload for each update.
        </p>
      </header>

      <.bar_chart
        id="sales"
        initial_data={@initial_data}
        x_key={:month}
        y_key={:sales}
        on_bar_click="bar_clicked"
        width={700}
        height={360}
        animation_duration={400}
      />

      <div class="flex flex-wrap gap-2">
        <button
          phx-click="randomize"
          class="rounded border px-3 py-1.5 text-sm hover:bg-base-200"
        >
          set_data (randomize)
        </button>
        <button
          phx-click="patch_feb"
          class="rounded border px-3 py-1.5 text-sm hover:bg-base-200"
        >
          patch Feb → 30,000
        </button>
        <button
          phx-click="remove_jan"
          class="rounded border px-3 py-1.5 text-sm hover:bg-base-200"
        >
          remove Jan
        </button>
      </div>

      <div :if={@last_action} class="text-sm text-base-content/70">
        <strong>Last action:</strong> {@last_action}
      </div>
    </div>
    """
  end
end
