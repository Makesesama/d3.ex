defmodule D3Ex.Components.LineChart do
  @moduledoc """
  Multi-line chart component with interactive tooltips and legends.

  ## Example

      <.line_chart
        id="trends-chart"
        data={@time_series_data}
        x_key={:date}
        y_key={:value}
        series_key={:metric}
        on_point_click="point_clicked"
        width={800}
        height={400}
      />

  ## Data Format

  For single line:

      [
        %{date: ~D[2024-01-01], value: 100},
        %{date: ~D[2024-01-02], value: 150},
        ...
      ]

  For multiple lines (use `series_key`):

      [
        %{date: ~D[2024-01-01], value: 100, metric: "sales"},
        %{date: ~D[2024-01-01], value: 80, metric: "costs"},
        %{date: ~D[2024-01-02], value: 150, metric: "sales"},
        %{date: ~D[2024-01-02], value: 90, metric: "costs"},
        ...
      ]

  ## Options

  - `x_key` - Key for x-axis values (required)
  - `y_key` - Key for y-axis values (required)
  - `series_key` - Key for grouping multiple lines (optional)
  - `curve_type` - Line curve type: "linear", "monotone", "step" (default: "monotone")
  - `show_points` - Show data points on lines (default: true)
  - `show_area` - Fill area under lines (default: false)
  - `show_grid` - Show grid lines (default: true)
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
    |> Map.put_new(:data, [])
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
      data-items={encode_data(@data)}
      data-config={encode_config(Map.merge(@config, %{
        x_key: @x_key,
        y_key: @y_key,
        series_key: @series_key,
        x_label: @x_label,
        y_label: @y_label
      }))}
      phx-update="ignore"
      class="d3-line-chart"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>

      <%= if @on_point_click do %>
        <input type="hidden" name="on_point_click" value={@on_point_click} />
      <% end %>

      <%= if @on_line_hover do %>
        <input type="hidden" name="on_line_hover" value={@on_line_hover} />
      <% end %>
    </div>
    """
  end
end
