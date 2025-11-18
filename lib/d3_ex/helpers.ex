defmodule D3Ex.Helpers do
  @moduledoc """
  Helper functions for D3Ex integration.

  This module provides utilities for loading D3.js and setting up
  D3Ex components in your Phoenix LiveView application.
  """

  use Phoenix.Component

  @doc """
  Renders a script tag to load D3.js from the server.

  This function provides a convenient way to include D3.js that's
  bundled with the D3Ex package, so you don't need to use a CDN
  or install D3.js separately via npm.

  ## Options

    * `:version` - D3.js version to load (default: "v7")
    * `:src` - Custom source URL (overrides the bundled version)

  ## Examples

      # In your root layout (lib/my_app_web/components/layouts/root.html.heex):
      <D3Ex.Helpers.d3_script />

      # Or with a specific version:
      <D3Ex.Helpers.d3_script version="v7" />

      # Or use a CDN:
      <D3Ex.Helpers.d3_script src="https://d3js.org/d3.v7.min.js" />

  ## Installation Methods Comparison

  ### Option 1: Server-hosted (Recommended for simplicity)
  ```heex
  <D3Ex.Helpers.d3_script />
  ```
  - No external dependencies
  - Works offline
  - Bundled with D3Ex
  - Good for development and production

  ### Option 2: CDN
  ```heex
  <D3Ex.Helpers.d3_script src="https://d3js.org/d3.v7.min.js" />
  ```
  - Uses external CDN
  - May be cached by browser
  - Requires internet connection

  ### Option 3: NPM (For custom builds)
  ```javascript
  // In assets/js/app.js:
  import * as d3 from "d3";
  window.d3 = d3;
  ```
  - Full control over D3 modules
  - Can tree-shake unused features
  - Integrated with your build process
  """
  def d3_script(assigns) do
    assigns =
      assigns
      |> assign_new(:version, fn -> "v7" end)
      |> assign_new(:src, fn -> nil end)
      |> assign_new(:path, fn assigns ->
        assigns[:src] || "/assets/d3.#{assigns[:version]}.min.js"
      end)

    ~H"""
    <script
      src={@path}
      type="text/javascript"
    >
    </script>
    """
  end

  @doc """
  Returns the path to the bundled D3.js file for a given version.

  ## Examples

      iex> D3Ex.Helpers.d3_path()
      "/assets/d3.v7.min.js"

      iex> D3Ex.Helpers.d3_path("v7")
      "/assets/d3.v7.min.js"
  """
  def d3_path(version \\ "v7") do
    "/assets/d3.#{version}.min.js"
  end
end
