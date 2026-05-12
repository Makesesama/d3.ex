defmodule D3ExDemoWeb.Components.Charts.StreamChart do
  @moduledoc """
  Example Phoenix `stream/3` ↔ D3 bridge built on `D3Ex.Component`. Lives in the
  demo app, not the library — D3Ex itself ships only the bridge primitives.

  Pairs with `assets/js/hooks/stream_chart.js`. The hook uses a MutationObserver
  on the hidden `phx-update="stream"` feed and re-feeds D3 whenever Phoenix
  mutates the list.

  Why this pattern is nice:

  - `stream_insert(socket, :points, p, limit: -200)` caps memory server-side —
    no hand-rolled ring buffer in assigns.
  - Reconnect semantics fall out of LiveView's stream protocol for free.
  - Same `stream_insert`/`stream_delete` you already use for tables.

  ## Example

      def mount(_params, _session, socket) do
        if connected?(socket), do: :timer.send_interval(250, self(), :tick)

        socket =
          socket
          |> stream_configure(:points, dom_id: &"pt-\#{&1.t}")
          |> stream(:points, [])

        {:ok, socket}
      end

      def handle_info(:tick, socket) do
        t = System.system_time(:millisecond)
        point = %{t: t, y: :math.sin(t / 1000)}
        {:noreply, stream_insert(socket, :points, point, limit: -200)}
      end

      def render(assigns) do
        ~H\"\"\"
        <.stream_chart id="ticks" stream={@streams.points} x_key={:t} y_key={:y} />
        \"\"\"
      end

  ## Options

  - `stream` - A `Phoenix.LiveView.LiveStream` reference (required)
  - `x_key`, `y_key` - Atom keys into each item (default: `:x`, `:y`)
  - `series_key` - Optional key for multi-line grouping
  - Plus the standard `width`/`height`/`margin`/`color_scheme`/`curve_type`/
    `show_points`/`show_area`/`show_grid`/`animation_duration`/`point_radius`

  ## Limitations

  Numeric x/y only — `data-*` attributes are strings, coerced via `Number(...)`.
  Use millisecond integers for timestamps (`System.system_time(:millisecond)`).
  """

  use D3Ex.Component

  @impl true
  def default_config do
    %{
      width: 800,
      height: 400,
      margin: %{top: 20, right: 80, bottom: 40, left: 60},
      color_scheme: "schemeCategory10",
      curve_type: "monotone",
      show_points: true,
      show_area: false,
      show_grid: true,
      animation_duration: 750,
      point_radius: 4
    }
  end

  @impl true
  def prepare_assigns(assigns) do
    unless Map.has_key?(assigns, :stream) do
      raise ArgumentError, """
      StreamChart requires a `:stream` prop pointing at a
      `Phoenix.LiveView.LiveStream`. See `Phoenix.LiveView.stream/3`.

          <.stream_chart id="ticks" stream={@streams.points} x_key={:t} y_key={:y} />
      """
    end

    assigns
    |> Map.put_new(:x_key, :x)
    |> Map.put_new(:y_key, :y)
    |> Map.put_new(:series_key, nil)
    |> Map.put_new(:x_label, nil)
    |> Map.put_new(:y_label, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="D3Stream"
      data-config={encode_config(Map.merge(@config, %{
        x_key: @x_key,
        y_key: @y_key,
        series_key: @series_key,
        x_label: @x_label,
        y_label: @y_label
      }))}
      class="d3-stream-chart"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <div id={"#{@id}-svg"} phx-update="ignore">
        <svg width={@config.width} height={@config.height}></svg>
      </div>

      <div
        id={"#{@id}-feed"}
        phx-update="stream"
        data-stream-feed
        style="display:none"
      >
        <div
          :for={{dom_id, item} <- @stream}
          id={dom_id}
          data-stream-item
          data-x={Map.get(item, @x_key)}
          data-y={Map.get(item, @y_key)}
          data-series={@series_key && Map.get(item, @series_key)}
        />
      </div>
    </div>
    """
  end
end
