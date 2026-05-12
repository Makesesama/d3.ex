defmodule D3ExDemoWeb.PieChartLive do
  use D3ExDemoWeb, :live_view

  import D3ExDemoWeb.Components.PieChart

  @initial_data [
    %{label: "Search", value: 38},
    %{label: "Direct", value: 24},
    %{label: "Referral", value: 18},
    %{label: "Social", value: 12},
    %{label: "Email", value: 8}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Pie chart (custom hook)",
       initial_data: @initial_data,
       last_action: nil
     )}
  end

  @impl true
  def handle_event("shuffle", _params, socket) do
    shuffled =
      Enum.map(@initial_data, fn slice ->
        %{slice | value: slice.value + :rand.uniform(20) - 10}
      end)
      |> Enum.filter(&(&1.value > 0))

    {:noreply,
     socket
     |> D3Ex.Live.set_data("traffic", shuffled)
     |> assign(:last_action, "set_data — new slice weights")}
  end

  @impl true
  def handle_event("slice_clicked", %{"label" => label, "value" => value}, socket) do
    {:noreply, assign(socket, :last_action, "clicked: #{label} (#{value})")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl px-6 py-8 space-y-6">
      <header class="space-y-1">
        <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:underline">
          ← home
        </.link>
        <h1 class="text-2xl font-semibold">Pie chart — custom hook</h1>
        <p class="text-sm text-base-content/70">
          A consumer-defined D3 component built with <code>D3Ex.Component</code>
          and <code>createD3Hook</code>. The hook file
          (<code>assets/js/hooks/pie_chart.js</code>) is ~80 lines, almost all
          of which is the D3 itself — the factory absorbs the LiveView
          lifecycle. Shows that <code>D3Ex.Live.set_data/3</code> works for
          custom components too, not just the built-ins.
        </p>
      </header>

      <.pie_chart
        id="traffic"
        initial_data={@initial_data}
        value_key={:value}
        label_key={:label}
        on_slice_click="slice_clicked"
      />

      <div class="flex flex-wrap gap-2">
        <button
          phx-click="shuffle"
          class="rounded border px-3 py-1.5 text-sm hover:bg-base-200"
        >
          set_data (shuffle weights)
        </button>
      </div>

      <div :if={@last_action} class="text-sm text-base-content/70">
        <strong>Last action:</strong> {@last_action}
      </div>
    </div>
    """
  end
end
