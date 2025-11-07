defmodule D3Ex.ConfigTest do
  use ExUnit.Case, async: true
  doctest D3Ex.Config

  describe "forces/1" do
    test "returns default configuration when no options provided" do
      config = D3Ex.Config.forces()

      assert config.charge == -300
      assert config.link.distance == 100
      assert config.collision.radius == 15
      assert config.center == 0.1
    end

    test "accepts custom charge value" do
      config = D3Ex.Config.forces(charge: -500)

      assert config.charge == -500
    end

    test "accepts link distance as number" do
      config = D3Ex.Config.forces(link: 150)

      assert config.link.distance == 150
      assert config.link.strength == 1
    end

    test "accepts detailed link configuration" do
      config = D3Ex.Config.forces(link: [distance: 200, strength: 0.5, iterations: 3])

      assert config.link.distance == 200
      assert config.link.strength == 0.5
      assert config.link.iterations == 3
    end

    test "accepts collision as number" do
      config = D3Ex.Config.forces(collision: 20)

      assert config.collision.radius == 20
      assert config.collision.strength == 1
    end

    test "accepts detailed collision configuration" do
      config = D3Ex.Config.forces(collision: [radius: 25, strength: 0.8])

      assert config.collision.radius == 25
      assert config.collision.strength == 0.8
    end

    test "accepts positioning forces" do
      config = D3Ex.Config.forces(x: [strength: 0.2], y: 0.3)

      assert config.x.strength == 0.2
      assert config.y.strength == 0.3
    end
  end

  describe "theme/1" do
    test "returns light theme" do
      config = D3Ex.Config.theme(:light)

      assert config.background == "#ffffff"
      assert config.text_color == "#000000"
      assert config.color_scheme == "schemeCategory10"
    end

    test "returns dark theme" do
      config = D3Ex.Config.theme(:dark)

      assert config.background == "#1a1a1a"
      assert config.text_color == "#ffffff"
      assert config.color_scheme == "schemeDark2"
    end

    test "returns corporate theme" do
      config = D3Ex.Config.theme(:corporate)

      assert config.background == "#f5f7fa"
      assert config.text_color == "#2c3e50"
      assert config.color_scheme == "schemeBlues"
    end

    test "returns pastel theme" do
      config = D3Ex.Config.theme(:pastel)

      assert config.color_scheme == "schemePastel1"
    end

    test "returns vibrant theme" do
      config = D3Ex.Config.theme(:vibrant)

      assert config.color_scheme == "schemeSet1"
    end

    test "returns monochrome theme" do
      config = D3Ex.Config.theme(:monochrome)

      assert config.color_scheme == "schemeGreys"
    end
  end

  describe "network_graph/1" do
    test "returns default configuration" do
      config = D3Ex.Config.network_graph()

      assert config.width == 800
      assert config.height == 600
      assert config.node_radius == 10
      assert config.link_width == 1
    end

    test "accepts custom size" do
      config = D3Ex.Config.network_graph(size: {1000, 800})

      assert config.width == 1000
      assert config.height == 800
    end

    test "applies theme by name" do
      config = D3Ex.Config.network_graph(theme: :dark)

      assert config.background == "#1a1a1a"
      assert config.text_color == "#ffffff"
    end

    test "includes force configuration" do
      config = D3Ex.Config.network_graph(forces: [charge: -400, link: 120])

      assert config.forces.charge == -400
      assert config.forces.link.distance == 120
    end

    test "includes interaction configuration" do
      config = D3Ex.Config.network_graph(interactions: [drag: true, zoom: true])

      assert config.interactions.drag.enabled == true
      assert config.interactions.zoom.enabled == true
    end

    test "sets custom node and link properties" do
      config = D3Ex.Config.network_graph(node_radius: 15, link_width: 2)

      assert config.node_radius == 15
      assert config.link_width == 2
    end
  end

  describe "bar_chart/1" do
    test "returns default configuration" do
      config = D3Ex.Config.bar_chart()

      assert config.width == 600
      assert config.height == 400
      assert config.bar_padding == 0.1
      assert config.orientation == :vertical
      assert config.show_values == false
      assert config.animation_duration == 750
    end

    test "accepts custom size" do
      config = D3Ex.Config.bar_chart(size: {800, 500})

      assert config.width == 800
      assert config.height == 500
    end

    test "accepts margin as keyword list" do
      config = D3Ex.Config.bar_chart(margin: [top: 30, right: 40, bottom: 50, left: 70])

      assert config.margin.top == 30
      assert config.margin.right == 40
      assert config.margin.bottom == 50
      assert config.margin.left == 70
    end

    test "applies theme" do
      config = D3Ex.Config.bar_chart(theme: :corporate)

      assert config.color_scheme == "schemeBlues"
    end

    test "accepts custom options" do
      config =
        D3Ex.Config.bar_chart(
          bar_padding: 0.3,
          orientation: :horizontal,
          show_values: true
        )

      assert config.bar_padding == 0.3
      assert config.orientation == :horizontal
      assert config.show_values == true
    end
  end

  describe "line_chart/1" do
    test "returns default configuration" do
      config = D3Ex.Config.line_chart()

      assert config.width == 800
      assert config.height == 400
      assert config.curve_type == :monotone
      assert config.show_points == true
      assert config.show_area == false
      assert config.show_grid == true
      assert config.point_radius == 4
    end

    test "accepts custom curve type" do
      config = D3Ex.Config.line_chart(curve: :step)

      assert config.curve_type == :step
    end

    test "accepts display options" do
      config =
        D3Ex.Config.line_chart(
          show_points: false,
          show_area: true,
          show_grid: false
        )

      assert config.show_points == false
      assert config.show_area == true
      assert config.show_grid == false
    end
  end

  describe "interactions/1" do
    test "returns empty map when no options" do
      config = D3Ex.Config.interactions()

      assert config == %{}
    end

    test "enables simple interactions" do
      config = D3Ex.Config.interactions(drag: true, zoom: true, hover: true)

      assert config.drag.enabled == true
      assert config.zoom.enabled == true
      assert config.hover.enabled == true
    end

    test "accepts detailed zoom configuration" do
      config = D3Ex.Config.interactions(zoom: [extent: [0.5, 5], constrain: true])

      assert config.zoom.enabled == true
      assert config.zoom.extent == [0.5, 5]
      assert config.zoom.constrain == true
    end

    test "accepts detailed select configuration" do
      config = D3Ex.Config.interactions(select: [multi: true])

      assert config.select.enabled == true
      assert config.select.multi == true
    end

    test "accepts detailed drag configuration" do
      config = D3Ex.Config.interactions(drag: [constrain: true])

      assert config.drag.enabled == true
      assert config.drag.constrain == true
    end

    test "ignores false and nil values" do
      config = D3Ex.Config.interactions(drag: false, zoom: nil, select: true)

      assert Map.has_key?(config, :select)
      refute Map.has_key?(config, :drag)
      refute Map.has_key?(config, :zoom)
    end
  end

  describe "merge/2" do
    test "merges two configurations" do
      config1 = %{width: 800, height: 600, color: "blue"}
      config2 = %{width: 1000, margin: 20}

      result = D3Ex.Config.merge(config1, config2)

      assert result.width == 1000
      assert result.height == 600
      assert result.color == "blue"
      assert result.margin == 20
    end

    test "chains with theme and custom config" do
      config =
        D3Ex.Config.theme(:dark)
        |> D3Ex.Config.merge(%{width: 1200, height: 900})
        |> D3Ex.Config.merge(%{custom_option: true})

      assert config.background == "#1a1a1a"
      assert config.width == 1200
      assert config.height == 900
      assert config.custom_option == true
    end
  end

  describe "responsive/1" do
    test "returns responsive configuration with defaults" do
      config = D3Ex.Config.responsive()

      assert config.responsive == true
      assert config.breakpoints.mobile == 320
      assert config.breakpoints.tablet == 768
      assert config.breakpoints.desktop == 1024
    end

    test "accepts custom breakpoints" do
      config =
        D3Ex.Config.responsive(
          breakpoints: %{small: 480, medium: 960, large: 1440}
        )

      assert config.breakpoints.small == 480
      assert config.breakpoints.medium == 960
      assert config.breakpoints.large == 1440
    end

    test "accepts device-specific configurations" do
      config =
        D3Ex.Config.responsive(
          mobile: %{width: 320, node_radius: 6},
          tablet: %{width: 768, node_radius: 8},
          desktop: %{width: 1200, node_radius: 12}
        )

      assert config.mobile.width == 320
      assert config.tablet.node_radius == 8
      assert config.desktop.width == 1200
    end
  end

  describe "integration tests" do
    test "compose complete network graph configuration" do
      config =
        D3Ex.Config.theme(:dark)
        |> D3Ex.Config.merge(
          D3Ex.Config.network_graph(
            size: {1200, 800},
            forces: [charge: -500, link: [distance: 150]],
            node_radius: 15
          )
        )
        |> D3Ex.Config.merge(%{
          custom_class: "my-graph",
          tooltip_enabled: true
        })

      # Has theme properties
      assert config.background == "#1a1a1a"
      assert config.color_scheme == "schemeDark2"

      # Has size
      assert config.width == 1200
      assert config.height == 800

      # Has forces
      assert config.forces.charge == -500
      assert config.forces.link.distance == 150

      # Has node config
      assert config.node_radius == 15

      # Has custom properties
      assert config.custom_class == "my-graph"
      assert config.tooltip_enabled == true
    end
  end
end
