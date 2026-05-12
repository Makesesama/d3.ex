defmodule D3ExDemoWeb.Components.Charts.BarChart do
  @moduledoc """
  Example bar chart built on `D3Ex.Component`. Lives in the demo app, not the
  library — D3Ex itself ships only the bridge primitives.

  Pairs with `assets/js/hooks/bar_chart.js`.

  ## Example

      <.bar_chart
        id="sales-chart"
        initial_data={@chart_data}
        x_key={:month}
        y_key={:sales}
        on_bar_click="bar_clicked"
        width={600}
        height={400}
      />

  `:initial_data` is consumed once at mount. For subsequent updates, use
  `D3Ex.Live.set_data/3`, `append/3`, `patch/3`, or `remove/3` with the
  component's `id`.

  ## Options

  - `initial_data` - Initial dataset
  - `x_key` - Key for x-axis values (also the identity key for `patch`/`remove`)
  - `y_key` - Key for y-axis values
  - `color_key` - Key for grouping/coloring bars (optional)
  - `x_label`, `y_label` - Axis labels
  - `on_bar_click`, `on_bar_hover` - LiveView event names
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
    |> Map.put_new(:initial_data, [])
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
      data-items={encode_data(@initial_data)}
      data-config={encode_config(Map.merge(@config, %{
        x_key: @x_key,
        y_key: @y_key,
        color_key: @color_key,
        x_label: @x_label,
        y_label: @y_label
      }))}
      data-events={encode_events(%{
        on_bar_click: @on_bar_click,
        on_bar_hover: @on_bar_hover
      })}
      phx-update="ignore"
      class="d3-bar-chart"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>
    </div>
    """
  end
end
