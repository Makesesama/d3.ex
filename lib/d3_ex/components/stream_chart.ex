defmodule D3Ex.Components.StreamChart do
  @moduledoc """
  Phoenix `stream/3` bridge — feeds a `Phoenix.LiveView.LiveStream` directly
  into a D3 chart.

  Unlike `BarChart`/`LineChart` (which take `:initial_data` and then receive
  deltas via `D3Ex.Live` helpers), this component consumes Phoenix's native
  stream protocol. You manage data with `stream_insert/4`, `stream_delete/3`,
  and `stream/4` (with `:reset` and `:limit`). The hook observes DOM mutations
  on a hidden feed element and re-renders D3.

  Why use this:

  - **Bounded server memory.** `stream_insert(socket, :points, p, limit: -200)`
    caps the dataset server-side; you don't have to maintain a ring buffer in
    `socket.assigns`. (Negative limit = keep the last N; positive limit keeps
    the first N and would discard your new appends.)
  - **Free reconnect.** Phoenix already defines what "the current dataset" is
    after a reconnect — `phx-update="stream"` handles it.
  - **Idiomatic.** Same `stream_insert`/`stream_delete` you already use for
    tables.

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
        <.stream_chart
          id="ticks"
          stream={@streams.points}
          x_key={:t}
          y_key={:y}
          renderer="line"
          width={700}
          height={360}
        />
        \"\"\"
      end

  ## Options

  - `stream` - A `Phoenix.LiveView.LiveStream` reference (required, e.g.
    `@streams.points`).
  - `x_key` - Atom key for x-axis values in each item (default: `:x`).
  - `y_key` - Atom key for y-axis values (default: `:y`).
  - `series_key` - Optional atom key for grouping multiple lines (default: `nil`).
  - `renderer` - Chart type. v1 supports `"line"` only (default: `"line"`).

  Plus the standard config props mirrored from `LineChart`: `width`, `height`,
  `margin`, `color_scheme`, `curve_type`, `show_points`, `show_area`,
  `show_grid`, `animation_duration`, `point_radius`.

  ## Limitations (v1)

  - **Numeric x/y only.** `data-*` attributes are strings; the hook coerces
    them with `Number(...)`. Use millisecond integers for timestamps
    (`System.system_time(:millisecond)`).
  - **No event handlers.** `on_point_click` etc. are not wired in v1.
  - **One renderer.** Only `"line"` is implemented.
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
    if Map.has_key?(assigns, :data) or Map.has_key?(assigns, :initial_data) do
      raise ArgumentError, """
      D3Ex.Components.StreamChart does not accept `:data` or `:initial_data`.
      It consumes a Phoenix `stream/3` reference directly:

          # In your LiveView mount:
          socket = stream(socket, :points, initial_points)

          # In your template:
          <.stream_chart id="ticks" stream={@streams.points} x_key={:t} y_key={:y} />

          # Then push updates with the standard Phoenix stream API:
          stream_insert(socket, :points, %{t: ..., y: ...}, limit: 200)
      """
    end

    unless Map.has_key?(assigns, :stream) do
      raise ArgumentError, """
      D3Ex.Components.StreamChart requires a `:stream` prop pointing at a
      `Phoenix.LiveView.LiveStream`. See `Phoenix.LiveView.stream/3`.

          <.stream_chart id="ticks" stream={@streams.points} x_key={:t} y_key={:y} />
      """
    end

    renderer = Map.get(assigns, :renderer, "line")

    unless renderer == "line" do
      raise ArgumentError, """
      D3Ex.Components.StreamChart v1 only supports renderer="line".
      Got: #{inspect(renderer)}.
      """
    end

    assigns
    |> Map.put(:renderer, renderer)
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
        y_label: @y_label,
        renderer: @renderer
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
