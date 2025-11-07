defmodule D3Ex.Components.BarChart do
  @moduledoc """
  Animated bar chart component with interactive features.

  ## Example

      <.bar_chart
        id="sales-chart"
        data={@chart_data}
        x_key={:month}
        y_key={:sales}
        on_bar_click="bar_clicked"
        width={600}
        height={400}
      />

  ## Data Format

  Data should be a list of maps:

      [
        %{month: "Jan", sales: 1000, region: "North"},
        %{month: "Feb", sales: 1500, region: "North"},
        ...
      ]

  ## Options

  - `x_key` - Key for x-axis values (required)
  - `y_key` - Key for y-axis values (required)
  - `color_key` - Key for grouping/coloring bars (optional)
  - `x_label` - Label for x-axis
  - `y_label` - Label for y-axis
  - `on_bar_click` - Event handler for bar clicks
  - `on_bar_hover` - Event handler for bar hover
  - `animation_duration` - Animation duration in ms (default: 750)
  """

  use D3Ex.Component

  @impl true
  def default_config do
    %{
      width: 600,
      height: 400,
      margin: %{top: 20, right: 20, bottom: 40, left: 60},
      color_scheme: "schemeCategory10",
      animation_duration: 750,
      bar_padding: 0.1,
      show_values: false
    }
  end

  @impl true
  def prepare_assigns(assigns) do
    assigns
    |> Map.put_new(:data, [])
    |> Map.put_new(:x_key, :x)
    |> Map.put_new(:y_key, :y)
    |> Map.put_new(:color_key, nil)
    |> Map.put_new(:x_label, nil)
    |> Map.put_new(:y_label, nil)
    |> Map.put_new(:on_bar_click, nil)
    |> Map.put_new(:on_bar_hover, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="D3BarChart"
      data-items={encode_data(@data)}
      data-config={encode_config(Map.merge(@config, %{
        x_key: @x_key,
        y_key: @y_key,
        color_key: @color_key,
        x_label: @x_label,
        y_label: @y_label
      }))}
      phx-update="ignore"
      class="d3-bar-chart"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>

      <%= if @on_bar_click do %>
        <input type="hidden" name="on_bar_click" value={@on_bar_click} />
      <% end %>

      <%= if @on_bar_hover do %>
        <input type="hidden" name="on_bar_hover" value={@on_bar_hover} />
      <% end %>
    </div>
    """
  end
end
