defmodule D3Ex.LiveTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.Utils

  defp build_socket do
    %Phoenix.LiveView.Socket{private: %{live_temp: %{}}}
  end

  defp events(socket), do: Utils.get_push_events(socket)

  describe "set_data/3" do
    test "emits id-scoped :set_data event" do
      socket =
        build_socket()
        |> D3Ex.Live.set_data("sales", [%{x: 1, y: 2}, %{x: 3, y: 4}])

      assert events(socket) == [["sales:set_data", %{data: [%{x: 1, y: 2}, %{x: 3, y: 4}]}]]
    end

    test "different ids do not collide" do
      socket =
        build_socket()
        |> D3Ex.Live.set_data("a", [%{v: 1}])
        |> D3Ex.Live.set_data("b", [%{v: 2}])

      assert events(socket) == [
               ["a:set_data", %{data: [%{v: 1}]}],
               ["b:set_data", %{data: [%{v: 2}]}]
             ]
    end
  end

  describe "append/3" do
    test "emits id-scoped :append event with items" do
      socket =
        build_socket()
        |> D3Ex.Live.append("metrics", [%{t: 1, v: 10}])

      assert events(socket) == [["metrics:append", %{items: [%{t: 1, v: 10}]}]]
    end

    test "accepts an empty list" do
      socket = build_socket() |> D3Ex.Live.append("metrics", [])
      assert events(socket) == [["metrics:append", %{items: []}]]
    end
  end

  describe "patch/3" do
    test "emits id-scoped :patch event with changes" do
      changes = [%{key: "Feb", changes: %{sales: 13_000}}]
      socket = build_socket() |> D3Ex.Live.patch("sales", changes)

      assert events(socket) == [["sales:patch", %{changes: changes}]]
    end
  end

  describe "remove/3" do
    test "emits id-scoped :remove event with ids" do
      socket = build_socket() |> D3Ex.Live.remove("sales", ["Jan", "Feb"])
      assert events(socket) == [["sales:remove", %{ids: ["Jan", "Feb"]}]]
    end
  end

  describe "id scoping across charts" do
    test "two charts with different ids on the same socket each get their own events" do
      socket =
        build_socket()
        |> D3Ex.Live.append("chart-a", [%{v: 1}])
        |> D3Ex.Live.set_data("chart-b", [%{v: 2}])

      assert events(socket) == [
               ["chart-a:append", %{items: [%{v: 1}]}],
               ["chart-b:set_data", %{data: [%{v: 2}]}]
             ]
    end
  end
end
