defmodule D3Ex.Components.StreamChartTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import D3Ex.Components.StreamChart, only: [component: 1]

  # `:for={{dom_id, item} <- @stream}` only requires an Enumerable yielding
  # {dom_id, item} pairs. A list of two-tuples renders identically to a real
  # Phoenix.LiveView.LiveStream at HEEx-render time and keeps tests free of
  # endpoint/socket plumbing.
  defp stream_fixture(items, dom_id_fun \\ fn i, item -> "pt-#{Map.get(item, :t, i)}" end) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> {dom_id_fun.(i, item), item} end)
  end

  describe "stream_chart component" do
    test "renders with hook, config, and the three-child structure" do
      assigns = %{
        id: "ticks",
        stream: stream_fixture([])
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "id=\"ticks\""
      assert result =~ "phx-hook=\"D3Stream\""
      assert result =~ "data-config="
      assert result =~ "id=\"ticks-svg\""
      assert result =~ "id=\"ticks-feed\""
      assert result =~ "phx-update=\"ignore\""
      assert result =~ "phx-update=\"stream\""
      assert result =~ "data-stream-feed"
    end

    test "renders one feed item per stream entry with data-x and data-y" do
      items = [
        %{t: 100, y: 0.5},
        %{t: 200, y: 0.7},
        %{t: 300, y: 0.9}
      ]

      assigns = %{
        id: "ticks",
        stream: stream_fixture(items),
        x_key: :t,
        y_key: :y
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "id=\"pt-100\""
      assert result =~ "id=\"pt-200\""
      assert result =~ "id=\"pt-300\""

      assert result =~ "data-x=\"100\""
      assert result =~ "data-y=\"0.5\""
      assert result =~ "data-x=\"300\""
      assert result =~ "data-y=\"0.9\""

      assert result =~ "data-stream-item"
    end

    test "emits data-series only when series_key is set" do
      items = [
        %{t: 1, y: 10, metric: "cpu"},
        %{t: 2, y: 20, metric: "memory"}
      ]

      with_series = %{
        id: "ticks",
        stream: stream_fixture(items),
        x_key: :t,
        y_key: :y,
        series_key: :metric
      }

      result = rendered_to_string(component(with_series))
      assert result =~ "data-series=\"cpu\""
      assert result =~ "data-series=\"memory\""

      without_series = %{
        id: "ticks",
        stream: stream_fixture(items),
        x_key: :t,
        y_key: :y
      }

      result = rendered_to_string(component(without_series))
      refute result =~ "data-series=\"cpu\""
    end

    test "applies custom dimensions to wrapper and SVG" do
      assigns = %{
        id: "ticks",
        stream: stream_fixture([]),
        width: 1000,
        height: 500
      }

      result = rendered_to_string(component(assigns))

      assert result =~ "width: 1000px"
      assert result =~ "height: 500px"
      assert result =~ "width=\"1000\""
      assert result =~ "height=\"500\""
    end

    test "uses default dimensions when not specified" do
      assigns = %{id: "ticks", stream: stream_fixture([])}

      result = rendered_to_string(component(assigns))

      assert result =~ "width=\"800\""
      assert result =~ "height=\"400\""
    end

    test "encodes axis/series keys into data-config for the hook" do
      assigns = %{
        id: "ticks",
        stream: stream_fixture([]),
        x_key: :t,
        y_key: :v,
        series_key: :group
      }

      result = rendered_to_string(component(assigns))

      assert result =~ ~s(&quot;x_key&quot;:&quot;t&quot;)
      assert result =~ ~s(&quot;y_key&quot;:&quot;v&quot;)
      assert result =~ ~s(&quot;series_key&quot;:&quot;group&quot;)
      assert result =~ ~s(&quot;renderer&quot;:&quot;line&quot;)
    end

    test "renders empty feed when stream has no items" do
      assigns = %{id: "empty", stream: stream_fixture([])}

      result = rendered_to_string(component(assigns))

      refute result =~ "data-stream-item"
      assert result =~ "id=\"empty-feed\""
    end
  end

  describe "validation" do
    test "raises with migration hint when :data is passed" do
      assigns = %{id: "ticks", stream: stream_fixture([]), data: []}

      assert_raise ArgumentError, ~r/does not accept.*:data.*stream_insert/s, fn ->
        rendered_to_string(component(assigns))
      end
    end

    test "raises with migration hint when :initial_data is passed" do
      assigns = %{id: "ticks", stream: stream_fixture([]), initial_data: []}

      assert_raise ArgumentError, ~r/does not accept.*initial_data.*stream_insert/s, fn ->
        rendered_to_string(component(assigns))
      end
    end

    test "raises when :stream is missing" do
      assigns = %{id: "ticks"}

      assert_raise ArgumentError, ~r/requires a `:stream` prop/s, fn ->
        rendered_to_string(component(assigns))
      end
    end

    test "raises when renderer is not supported" do
      assigns = %{
        id: "ticks",
        stream: stream_fixture([]),
        renderer: "scatter"
      }

      assert_raise ArgumentError, ~r/only supports renderer="line"/, fn ->
        rendered_to_string(component(assigns))
      end
    end
  end
end
