defmodule D3ExDemoWeb.Components.Charts.LineChart do
  @moduledoc """
  Example multi-line chart built on `D3Ex.Component`. Lives in the demo app,
  not the library — D3Ex itself ships only the bridge primitives.

  Pairs with `assets/js/hooks/line_chart.js`.

  ## Example

      <.line_chart
        id="trends-chart"
        initial_data={@time_series_data}
        x_key={:date}
        y_key={:value}
        series_key={:metric}
        on_point_click="point_clicked"
        width={800}
        height={400}
      />

  `:initial_data` is consumed once at mount. For subsequent updates, use
  `D3Ex.Live.set_data/3`, `append/3`, `patch/3`, or `remove/3`.

  ## Options

  - `x_key`, `y_key` - Keys for the axes
  - `series_key` - Optional key for grouping multiple lines
  - `curve_type` - "linear" | "monotone" | "step" (default: "monotone")
  - `show_points`, `show_area`, `show_grid` - Visual toggles
  - `on_point_click`, `on_line_hover` - LiveView event names
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
    assigns
    |> Map.put_new(:initial_data, [])
    |> Map.put_new(:x_key, :x)
    |> Map.put_new(:y_key, :y)
    |> Map.put_new(:series_key, nil)
    |> Map.put_new(:x_label, nil)
    |> Map.put_new(:y_label, nil)
    |> Map.put_new(:on_point_click, nil)
    |> Map.put_new(:on_line_hover, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="D3LineChart"
      data-items={encode_data(@initial_data)}
      data-config={encode_config(Map.merge(@config, %{
        x_key: @x_key,
        y_key: @y_key,
        series_key: @series_key,
        x_label: @x_label,
        y_label: @y_label
      }))}
      data-events={encode_events(%{
        on_point_click: @on_point_click,
        on_line_hover: @on_line_hover
      })}
      phx-update="ignore"
      class="d3-line-chart"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>
    </div>
    """
  end
end
