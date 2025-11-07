defmodule D3Ex.ComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  describe "D3Ex.Component" do
    defmodule TestComponent do
      use D3Ex.Component

      @impl true
      def default_config do
        %{
          width: 800,
          height: 600,
          test_option: "default"
        }
      end

      @impl true
      def prepare_assigns(assigns) do
        assigns
        |> Map.put_new(:data, [])
        |> Map.put_new(:label, "Test Chart")
      end

      @impl true
      def render(assigns) do
        ~H"""
        <div
          id={@id}
          phx-hook="TestChart"
          data-items={encode_data(@data)}
          data-config={encode_config(@config)}
          class="test-component"
        >
          <svg width={@config.width} height={@config.height}></svg>
          <span class="label"><%= @label %></span>
        </div>
        """
      end
    end

    test "generates unique ID when not provided" do
      assigns = %{}
      result = rendered_to_string(TestComponent.component(assigns))

      assert result =~ ~r/id="d3ex-\d+"/
    end

    test "uses provided ID" do
      assigns = %{id: "my-custom-id"}
      result = rendered_to_string(TestComponent.component(assigns))

      assert result =~ ~r/id="my-custom-id"/
    end

    test "merges config with defaults" do
      assigns = %{id: "test", config: %{width: 1000}}
      result = rendered_to_string(TestComponent.component(assigns))

      # Width should be overridden to 1000
      assert result =~ "width=\"1000\""
      # Height should use default 600
      assert result =~ "height=\"600\""
    end

    test "allows config via top-level assigns" do
      assigns = %{id: "test", width: 1200, height: 800}
      result = rendered_to_string(TestComponent.component(assigns))

      assert result =~ "width=\"1200\""
      assert result =~ "height=\"800\""
    end

    test "prepares default assigns" do
      assigns = %{id: "test"}
      result = rendered_to_string(TestComponent.component(assigns))

      # Should have default label
      assert result =~ "Test Chart"
    end

    test "encodes data to JSON" do
      assigns = %{id: "test", data: [%{x: 1, y: 2}, %{x: 3, y: 4}]}
      result = rendered_to_string(TestComponent.component(assigns))

      assert result =~ "data-items="
      assert result =~ Jason.encode!([%{x: 1, y: 2}, %{x: 3, y: 4}])
    end
  end

  describe "ensure_id/1" do
    test "adds ID when missing" do
      assigns = %{}
      result = D3Ex.Component.ensure_id(assigns)

      assert Map.has_key?(result, :id)
      assert result.id =~ ~r/^d3ex-\d+$/
    end

    test "preserves existing ID" do
      assigns = %{id: "existing"}
      result = D3Ex.Component.ensure_id(assigns)

      assert result.id == "existing"
    end
  end

  describe "encode_data/1" do
    test "encodes list of maps" do
      data = [%{a: 1}, %{b: 2}]
      result = D3Ex.Component.encode_data(data)

      assert result == Jason.encode!(data)
    end

    test "encodes empty list" do
      result = D3Ex.Component.encode_data([])
      assert result == "[]"
    end
  end

  describe "merge_config/2" do
    test "merges user config with defaults" do
      assigns = %{config: %{width: 1000, custom: "value"}}
      defaults = %{width: 800, height: 600}

      result = D3Ex.Component.merge_config(assigns, defaults)

      assert result.config.width == 1000
      assert result.config.height == 600
      assert result.config.custom == "value"
    end

    test "extracts config from top-level assigns" do
      assigns = %{width: 1200, height: 900}
      defaults = %{width: 800, height: 600}

      result = D3Ex.Component.merge_config(assigns, defaults)

      assert result.config.width == 1200
      assert result.config.height == 900
    end
  end
end
