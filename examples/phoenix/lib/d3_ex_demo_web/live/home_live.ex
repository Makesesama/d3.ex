defmodule D3ExDemoWeb.HomeLive do
  use D3ExDemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "D3Ex Demo")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl px-6 py-12 space-y-8">
      <header class="space-y-2">
        <h1 class="text-3xl font-semibold">D3Ex Demo</h1>
        <p class="text-base-content/70">
          Live demos of <code>D3Ex</code> — a thin bridge between Phoenix LiveView
          and D3.js. Each chart consumes <code>initial_data</code> once at mount
          and receives streaming updates via <code>D3Ex.Live</code>, so the wire
          payload per update is a tiny delta instead of a re-serialized dataset.
        </p>
      </header>

      <ul class="grid gap-4 md:grid-cols-2">
        <li>
          <.link
            navigate={~p"/bar"}
            class="block rounded-lg border p-5 hover:bg-base-200 transition"
          >
            <div class="text-lg font-medium">Bar chart</div>
            <p class="text-sm text-base-content/70">
              <code>set_data</code>, <code>patch</code>, <code>remove</code>
              demonstrated via buttons.
            </p>
          </.link>
        </li>

        <li>
          <.link
            navigate={~p"/line"}
            class="block rounded-lg border p-5 hover:bg-base-200 transition"
          >
            <div class="text-lg font-medium">Streaming line chart</div>
            <p class="text-sm text-base-content/70">
              <code>append</code> on a 500&nbsp;ms tick. Watch the WS frame size
              in DevTools — each tick is a 2-point delta.
            </p>
          </.link>
        </li>

        <li>
          <.link
            navigate={~p"/network"}
            class="block rounded-lg border p-5 hover:bg-base-200 transition"
          >
            <div class="text-lg font-medium">Network graph</div>
            <p class="text-sm text-base-content/70">
              <code>add_node</code>, <code>add_link</code>, <code>remove_node</code>
              against a force-directed layout.
            </p>
          </.link>
        </li>

        <li>
          <.link
            navigate={~p"/dashboard"}
            class="block rounded-lg border p-5 hover:bg-base-200 transition"
          >
            <div class="text-lg font-medium">Dashboard</div>
            <p class="text-sm text-base-content/70">
              All three chart types on one page, sharing a single PubSub tick.
            </p>
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
