defmodule D3ExDemoWeb.Components.PieChart do
  @moduledoc """
  Demo custom D3 component built on `D3Ex.Component`. Exists to exercise the
  `createD3Hook` factory end-to-end from an out-of-library consumer — the
  built-in chart components are interesting cases too, but they live inside
  the library, so the only proof that the factory is *usable from outside*
  is a real consumer that imports from `D3Ex` like an app would.

  Pairs with `assets/js/hooks/pie_chart.js`.
  """

  use D3Ex.Component

  @impl true
  def default_config do
    %{
      width: 480,
      height: 480,
      inner_radius: 0,
      outer_radius: 200,
      color_scheme: "schemeCategory10",
      animation_duration: 600
    }
  end

  @impl true
  def prepare_assigns(assigns) do
    assigns
    |> Map.put_new(:initial_data, [])
    |> Map.put_new(:value_key, :value)
    |> Map.put_new(:label_key, :label)
    |> Map.put_new(:on_slice_click, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="D3PieChart"
      data-items={encode_data(@initial_data)}
      data-config={encode_config(Map.merge(@config, %{
        value_key: @value_key,
        label_key: @label_key
      }))}
      data-events={encode_events(%{on_slice_click: @on_slice_click})}
      phx-update="ignore"
      class="d3-pie-chart"
      style={"width: #{@config.width}px; height: #{@config.height}px;"}
    >
      <svg width={@config.width} height={@config.height}></svg>
    </div>
    """
  end
end
