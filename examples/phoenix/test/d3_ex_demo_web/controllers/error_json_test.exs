defmodule D3ExDemoWeb.ErrorJSONTest do
  use D3ExDemoWeb.ConnCase, async: true

  test "renders 404" do
    assert D3ExDemoWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert D3ExDemoWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
