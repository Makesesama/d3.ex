defmodule D3ExTest do
  use ExUnit.Case
  doctest D3Ex

  test "returns version" do
    assert D3Ex.version() == "0.2.0"
  end
end
