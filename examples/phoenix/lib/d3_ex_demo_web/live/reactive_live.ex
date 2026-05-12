defmodule D3ExDemoWeb.ReactiveLive do
  @moduledoc """
  Demonstrates server-orchestrated reactivity across multiple D3 components.

  Clicking a bar fires `on_bar_click` to the server. The LiveView responds by
  emitting three id-scoped events:

    * `D3Ex.Live.patch/3` on `"counts"` — bumps the clicked bar's value
    * `D3Ex.Live.append/3` on `"history"` — pushes a point onto a line chart
    * `assign/3` — updates server-rendered status text

  Clicking a point on the line chart fires `on_point_click`. The server
  responds by `D3Ex.Live.set_data/3`-resetting the bar chart back to baseline.

  The full page is driven by the server, but only deltas cross the wire.
  """

  use D3ExDemoWeb, :live_view

  import D3ExDemoWeb.Components.Charts.BarChart
  import D3ExDemoWeb.Components.Charts.LineChart

  @categories ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"]

  defp initial_counts do
    Enum.map(@categories, &%{category: &1, count: 10})
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Reactive cascade")
     |> assign(:initial_counts, initial_counts())
     |> assign(:counts, Map.new(@categories, &{&1, 10}))
     |> assign(:click_index, 0)
     |> assign(:last_action, nil)}
  end

  @impl true
  def handle_event("bump", %{"category" => category}, socket) do
    new_value = Map.fetch!(socket.assigns.counts, category) + 5
    new_index = socket.assigns.click_index + 1

    point = %{idx: new_index, value: new_value, category: category}

    {:noreply,
     socket
     |> D3Ex.Live.patch("counts", [%{key: category, changes: %{count: new_value}}])
     |> D3Ex.Live.append("history", [point])
     |> update(:counts, &Map.put(&1, category, new_value))
     |> assign(:click_index, new_index)
     |> assign(
       :last_action,
       "clicked #{category} → bar patched, history appended (##{new_index})"
     )}
  end

  @impl true
  def handle_event("history_point", %{"category" => category, "idx" => idx}, socket) do
    {:noreply,
     socket
     |> D3Ex.Live.set_data("counts", initial_counts())
     |> D3Ex.Live.set_data("history", [])
     |> assign(:counts, Map.new(@categories, &{&1, 10}))
     |> assign(:click_index, 0)
     |> assign(:last_action, "history point ##{idx} (#{category}) clicked → reset everything")}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> D3Ex.Live.set_data("counts", initial_counts())
     |> D3Ex.Live.set_data("history", [])
     |> assign(:counts, Map.new(@categories, &{&1, 10}))
     |> assign(:click_index, 0)
     |> assign(:last_action, "reset")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-6 py-8 space-y-6">
      <header class="space-y-1">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:underline">
          ← home
        </.link>
        <h1 class="text-2xl font-semibold">Reactive cascade</h1>
        <p class="text-sm text-base-content/70">
          One click on a bar → the server orchestrates a <code>patch</code> on the
          bar chart, an <code>append</code> on the line chart, and a server-rendered
          status update. Clicking a point on the line chart triggers a full reset.
          Nothing on the page is driven client-side beyond the D3 rendering itself.
        </p>
      </header>

      <section class="space-y-2">
        <h2 class="text-sm font-medium text-base-content/60 uppercase tracking-wide">
          Counts — click a bar
        </h2>
        <.bar_chart
          id="counts"
          initial_data={@initial_counts}
          x_key={:category}
          y_key={:count}
          on_bar_click="bump"
          width={700}
          height={300}
          animation_duration={300}
        />
      </section>

      <section class="space-y-2">
        <h2 class="text-sm font-medium text-base-content/60 uppercase tracking-wide">
          Click history — click a point to reset
        </h2>
        <.line_chart
          id="history"
          initial_data={[]}
          x_key={:idx}
          y_key={:value}
          series_key={:category}
          on_point_click="history_point"
          width={700}
          height={300}
          show_area={false}
          animation_duration={200}
        />
      </section>

      <div class="flex flex-wrap items-center gap-3">
        <button
          phx-click="reset"
          class="rounded border px-3 py-1.5 text-sm hover:bg-base-200"
        >
          reset
        </button>
        <span class="text-sm text-base-content/70">
          <strong>{@click_index}</strong> clicks recorded
        </span>
      </div>

      <div :if={@last_action} class="text-sm text-base-content/70">
        <strong>Last action:</strong> {@last_action}
      </div>
    </div>
    """
  end
end
