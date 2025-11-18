defmodule D3Ex.Config do
  @moduledoc """
  Configuration builders and presets for D3 components.

  This module provides helper functions to build common configuration patterns,
  making it easier to work with D3Ex components without verbose boilerplate.

  ## Philosophy

  Following the VegaLite.ex pattern, we provide ergonomic helpers to build
  configuration maps that are passed to JavaScript for rendering.

  ## Examples

      # Build network graph configuration
      config =
        D3Ex.Config.network_graph(
          size: {1000, 800},
          forces: [charge: -400, link: [distance: 150]],
          theme: :dark
        )

      # Use in component
      <.network_graph
        id="graph"
        nodes={@nodes}
        links={@links}
        config={config}
      />

      # Chain configurations
      config =
        D3Ex.Config.theme(:dark)
        |> D3Ex.Config.merge(%{width: 1200, height: 900})
        |> D3Ex.Config.merge(D3Ex.Config.forces(charge: -500))
  """

  @doc """
  Build force configuration for network graphs.

  ## Options

    * `:charge` - Charge force strength (default: -300)
    * `:link` - Link force config as keyword list or number
      * When number: used as distance
      * When keyword: can specify `:distance`, `:strength`, `:iterations`
    * `:collision` - Collision force radius or config
    * `:center` - Center force strength (default: 0.1)
    * `:x` - X positioning force strength
    * `:y` - Y positioning force strength

  ## Examples

      # Simple
      forces(charge: -300, link: 100, collision: 15)

      # Advanced
      forces(
        charge: -500,
        link: [distance: 150, strength: 1, iterations: 2],
        collision: [radius: 20, strength: 1],
        center: 0.1,
        x: [strength: 0.1],
        y: [strength: 0.1]
      )

  Returns a map suitable for the `forces` config option.
  """
  def forces(opts \\ []) do
    %{
      charge: opts[:charge] || -300,
      link: normalize_link_force(opts[:link]),
      collision: normalize_collision_force(opts[:collision]),
      center: opts[:center] || 0.1
    }
    |> maybe_add(:x, normalize_positioning_force(opts[:x]))
    |> maybe_add(:y, normalize_positioning_force(opts[:y]))
  end

  defp normalize_link_force(nil), do: %{distance: 100, strength: 1}

  defp normalize_link_force(distance) when is_number(distance),
    do: %{distance: distance, strength: 1}

  defp normalize_link_force(opts) when is_list(opts) do
    %{
      distance: opts[:distance] || 100,
      strength: opts[:strength] || 1,
      iterations: opts[:iterations] || 1
    }
  end

  defp normalize_collision_force(nil), do: %{radius: 15, strength: 1}

  defp normalize_collision_force(radius) when is_number(radius),
    do: %{radius: radius, strength: 1}

  defp normalize_collision_force(opts) when is_list(opts) do
    %{
      radius: opts[:radius] || 15,
      strength: opts[:strength] || 1
    }
  end

  defp normalize_positioning_force(nil), do: nil
  defp normalize_positioning_force(strength) when is_number(strength), do: %{strength: strength}

  defp normalize_positioning_force(opts) when is_list(opts) do
    %{strength: opts[:strength] || 0.1}
  end

  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, key, value), do: Map.put(map, key, value)

  @doc """
  Build preset theme configuration.

  ## Available Themes

    * `:light` - Light background with dark text
    * `:dark` - Dark background with light text
    * `:corporate` - Professional blue theme
    * `:pastel` - Soft pastel colors
    * `:vibrant` - Bold, vibrant colors
    * `:monochrome` - Grayscale theme

  ## Examples

      config = D3Ex.Config.theme(:dark)
      # => %{
      #   background: "#1a1a1a",
      #   text_color: "#ffffff",
      #   grid_color: "#333333",
      #   color_scheme: "schemeDark2"
      # }

  Returns a map with theme settings.
  """
  def theme(:light) do
    %{
      background: "#ffffff",
      text_color: "#000000",
      grid_color: "#e5e5e5",
      color_scheme: "schemeCategory10",
      node_stroke: "#ffffff",
      link_color: "#999999"
    }
  end

  def theme(:dark) do
    %{
      background: "#1a1a1a",
      text_color: "#ffffff",
      grid_color: "#333333",
      color_scheme: "schemeDark2",
      node_stroke: "#000000",
      link_color: "#666666"
    }
  end

  def theme(:corporate) do
    %{
      background: "#f5f7fa",
      text_color: "#2c3e50",
      grid_color: "#d1d8e0",
      color_scheme: "schemeBlues",
      node_stroke: "#ffffff",
      link_color: "#95a5a6"
    }
  end

  def theme(:pastel) do
    %{
      background: "#fefefe",
      text_color: "#5a5a5a",
      grid_color: "#ebebeb",
      color_scheme: "schemePastel1",
      node_stroke: "#ffffff",
      link_color: "#d4d4d4"
    }
  end

  def theme(:vibrant) do
    %{
      background: "#ffffff",
      text_color: "#000000",
      grid_color: "#eeeeee",
      color_scheme: "schemeSet1",
      node_stroke: "#ffffff",
      link_color: "#888888"
    }
  end

  def theme(:monochrome) do
    %{
      background: "#ffffff",
      text_color: "#333333",
      grid_color: "#cccccc",
      color_scheme: "schemeGreys",
      node_stroke: "#ffffff",
      link_color: "#999999"
    }
  end

  @doc """
  Build complete network graph configuration.

  ## Options

    * `:size` - Tuple of {width, height} (default: {800, 600})
    * `:forces` - Force configuration (see `forces/1`)
    * `:theme` - Theme name or theme map
    * `:interactions` - Interaction settings
    * `:node_radius` - Default node radius (default: 10)
    * `:link_width` - Default link width (default: 1)

  ## Examples

      config = D3Ex.Config.network_graph(
        size: {1000, 800},
        forces: [charge: -400, link: [distance: 150]],
        theme: :dark,
        interactions: [drag: true, zoom: true, select: true],
        node_radius: 12
      )

  Returns a complete configuration map.
  """
  def network_graph(opts \\ []) do
    {width, height} = opts[:size] || {800, 600}
    theme_config = opts[:theme]

    base_config = %{
      width: width,
      height: height,
      node_radius: opts[:node_radius] || 10,
      link_width: opts[:link_width] || 1
    }

    # Apply theme
    config =
      if theme_config do
        theme_map = if is_atom(theme_config), do: theme(theme_config), else: theme_config
        Map.merge(base_config, theme_map)
      else
        Map.merge(base_config, theme(:light))
      end

    # Add forces
    config =
      if opts[:forces] do
        Map.put(config, :forces, forces(opts[:forces]))
      else
        config
      end

    # Add interactions
    config =
      if opts[:interactions] do
        Map.put(config, :interactions, interactions(opts[:interactions]))
      else
        config
      end

    config
  end

  @doc """
  Build bar chart configuration.

  ## Options

    * `:size` - Tuple of {width, height}
    * `:margin` - Margin map or keyword list
    * `:theme` - Theme name
    * `:bar_padding` - Padding between bars (0-1, default: 0.1)
    * `:orientation` - `:vertical` or `:horizontal`
    * `:show_values` - Show values on bars (default: false)
    * `:animation_duration` - Animation duration in ms

  ## Examples

      config = D3Ex.Config.bar_chart(
        size: {600, 400},
        margin: [top: 20, right: 20, bottom: 40, left: 60],
        theme: :corporate,
        bar_padding: 0.2,
        show_values: true
      )
  """
  def bar_chart(opts \\ []) do
    {width, height} = opts[:size] || {600, 400}

    base_config = %{
      width: width,
      height: height,
      margin: normalize_margin(opts[:margin]),
      bar_padding: opts[:bar_padding] || 0.1,
      orientation: opts[:orientation] || :vertical,
      show_values: opts[:show_values] || false,
      animation_duration: opts[:animation_duration] || 750
    }

    # Apply theme if provided
    if theme_name = opts[:theme] do
      Map.merge(base_config, theme(theme_name))
    else
      base_config
    end
  end

  @doc """
  Build line chart configuration.

  ## Options

    * `:size` - Tuple of {width, height}
    * `:margin` - Margin configuration
    * `:theme` - Theme name
    * `:curve` - Curve type: :linear, :monotone, :step, :basis
    * `:show_points` - Show data points (default: true)
    * `:show_area` - Fill area under line (default: false)
    * `:show_grid` - Show grid lines (default: true)
    * `:point_radius` - Radius of data points

  ## Examples

      config = D3Ex.Config.line_chart(
        size: {800, 400},
        curve: :monotone,
        show_points: true,
        show_area: true,
        show_grid: true
      )
  """
  def line_chart(opts \\ []) do
    {width, height} = opts[:size] || {800, 400}

    base_config = %{
      width: width,
      height: height,
      margin: normalize_margin(opts[:margin]),
      curve_type: opts[:curve] || :monotone,
      show_points: opts[:show_points] || true,
      show_area: opts[:show_area] || false,
      show_grid: opts[:show_grid] || true,
      point_radius: opts[:point_radius] || 4,
      animation_duration: opts[:animation_duration] || 750
    }

    # Apply theme if provided
    if theme_name = opts[:theme] do
      Map.merge(base_config, theme(theme_name))
    else
      base_config
    end
  end

  @doc """
  Build interaction configuration.

  ## Options

    * `:drag` - Enable dragging (boolean or keyword list)
    * `:zoom` - Enable zoom/pan (boolean or keyword list)
      * `:extent` - Zoom extent as [min, max]
      * `:constrain` - Constrain to bounds
    * `:select` - Enable selection (boolean or keyword list)
      * `:multi` - Allow multiple selection
    * `:hover` - Enable hover effects

  ## Examples

      # Simple
      interactions(drag: true, zoom: true, select: true)

      # Advanced
      interactions(
        drag: [constrain: true],
        zoom: [extent: [0.1, 10], constrain: true],
        select: [multi: false],
        hover: true
      )
  """
  def interactions(opts \\ []) do
    %{}
    |> maybe_add(:drag, normalize_interaction(opts[:drag], :drag))
    |> maybe_add(:zoom, normalize_interaction(opts[:zoom], :zoom))
    |> maybe_add(:select, normalize_interaction(opts[:select], :select))
    |> maybe_add(:hover, normalize_interaction(opts[:hover], :hover))
  end

  defp normalize_interaction(nil, _type), do: nil
  defp normalize_interaction(false, _type), do: nil
  defp normalize_interaction(true, _type), do: %{enabled: true}

  defp normalize_interaction(opts, :zoom) when is_list(opts) do
    %{
      enabled: true,
      extent: opts[:extent] || [0.1, 10],
      constrain: opts[:constrain] || false
    }
  end

  defp normalize_interaction(opts, :select) when is_list(opts) do
    %{
      enabled: true,
      multi: opts[:multi] || false
    }
  end

  defp normalize_interaction(opts, :drag) when is_list(opts) do
    %{
      enabled: true,
      constrain: opts[:constrain] || false
    }
  end

  defp normalize_interaction(opts, :hover) when is_list(opts) do
    %{enabled: true}
  end

  defp normalize_margin(nil) do
    %{top: 20, right: 20, bottom: 40, left: 60}
  end

  defp normalize_margin(margin) when is_list(margin) do
    %{
      top: margin[:top] || 20,
      right: margin[:right] || 20,
      bottom: margin[:bottom] || 40,
      left: margin[:left] || 60
    }
  end

  defp normalize_margin(margin) when is_map(margin), do: margin

  @doc """
  Merge two configuration maps.

  Later values override earlier values. Useful for composing configurations.

  ## Examples

      config =
        D3Ex.Config.theme(:dark)
        |> D3Ex.Config.merge(%{width: 1000, height: 800})
        |> D3Ex.Config.merge(D3Ex.Config.forces(charge: -500))

      # Or use with network_graph
      base = D3Ex.Config.network_graph(theme: :dark)
      custom = %{node_radius: 15, link_width: 2}
      config = D3Ex.Config.merge(base, custom)
  """
  def merge(config1, config2) do
    Map.merge(config1, config2)
  end

  @doc """
  Build a responsive configuration that adapts to screen size.

  ## Options

    * `:breakpoints` - Map of breakpoint names to widths
    * `:default` - Default configuration
    * `:mobile` - Mobile configuration
    * `:tablet` - Tablet configuration
    * `:desktop` - Desktop configuration

  ## Examples

      config = D3Ex.Config.responsive(
        breakpoints: %{mobile: 320, tablet: 768, desktop: 1024},
        default: D3Ex.Config.network_graph(size: {800, 600}),
        mobile: %{width: 320, height: 400, node_radius: 6},
        tablet: %{width: 768, height: 600},
        desktop: %{width: 1200, height: 800}
      )

  Note: Responsive configuration requires client-side handling.
  """
  def responsive(opts \\ []) do
    %{
      responsive: true,
      breakpoints: opts[:breakpoints] || %{mobile: 320, tablet: 768, desktop: 1024},
      default: opts[:default] || %{},
      mobile: opts[:mobile] || %{},
      tablet: opts[:tablet] || %{},
      desktop: opts[:desktop] || %{}
    }
  end
end
