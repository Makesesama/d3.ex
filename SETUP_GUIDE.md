# D3Ex Setup Guide

Quick setup instructions for integrating D3Ex into your Phoenix LiveView application.

## Prerequisites

- Phoenix 1.7+ with LiveView 0.20+
- Elixir 1.14+
- D3.js v7+

## Step 1: Add Dependency

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:d3_ex, "~> 0.1.0"}
  ]
end
```

Run:
```bash
mix deps.get
```

## Step 2: Install D3.js

### Option A: Via CDN (Simplest)

Add to your `lib/my_app_web/components/layouts/root.html.heex`:

```heex
<script src="https://d3js.org/d3.v7.min.js"></script>
```

### Option B: Via NPM (Recommended for Production)

```bash
cd assets
npm install d3
```

Then in `assets/js/app.js`:

```javascript
import * as d3 from "d3";
window.d3 = d3;
```

## Step 3: Copy JavaScript Hooks

Copy the D3Ex hooks to your project:

```bash
mkdir -p assets/js/hooks
cp deps/d3_ex/priv/static/js/d3_hooks.js assets/js/hooks/
```

## Step 4: Register Hooks

In your `assets/js/app.js`:

```javascript
import {
  D3NetworkGraph,
  D3BarChart,
  D3LineChart
} from "./hooks/d3_hooks.js"

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {
    D3NetworkGraph,
    D3BarChart,
    D3LineChart
  }
})
```

## Step 5: Use Components

In your LiveView:

```elixir
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view
  import D3Ex.Components.NetworkGraph

  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      nodes: [
        %{id: "1", label: "Node 1"},
        %{id: "2", label: "Node 2"}
      ],
      links: [
        %{source: "1", target: "2"}
      ]
    )}
  end

  def render(assigns) do
    ~H"""
    <.network_graph
      id="my-graph"
      nodes={@nodes}
      links={@links}
    />
    """
  end
end
```

## Step 6: Test It Out

1. Start your Phoenix server:
   ```bash
   mix phx.server
   ```

2. Navigate to your LiveView route

3. You should see your D3 visualization!

## Troubleshooting

### "D3.js is not loaded" Error

Make sure D3.js is loaded before LiveView initializes. If using NPM, ensure:

```javascript
import * as d3 from "d3";
window.d3 = d3; // Important!
```

### Components Not Rendering

1. Check browser console for errors
2. Verify hooks are registered correctly
3. Make sure `phx-hook` attribute matches hook name
4. Ensure D3.js is loaded (check `window.d3` in console)

### LiveView Not Updating Visualization

1. Make sure you're using `phx-update="ignore"` on the component container
2. Check that event handlers are defined in the LiveView
3. Verify data format matches component expectations

### Performance Issues

1. Use incremental updates instead of full data replacement
2. Throttle high-frequency events (dragging, zooming)
3. Consider using Canvas for large datasets (>1000 elements)
4. Profile with browser DevTools

## Next Steps

- Check out the [examples](examples/) directory
- Read the [Custom Components Guide](examples/CUSTOM_COMPONENTS_GUIDE.md)
- Review the [API documentation](https://hexdocs.pm/d3_ex)
- Build your own custom visualizations!

## Getting Help

- Open an issue on GitHub
- Check existing issues for solutions
- Review the documentation
- Ask in Elixir Forum or Discord

## Example Project Structure

```
my_app/
├── assets/
│   ├── js/
│   │   ├── app.js              # Register hooks here
│   │   └── hooks/
│   │       └── d3_hooks.js     # Copy from d3_ex
│   └── package.json
├── lib/
│   └── my_app_web/
│       ├── live/
│       │   └── dashboard_live.ex  # Your LiveView
│       └── components/
│           └── layouts/
│               └── root.html.heex  # Include D3.js here
└── mix.exs                    # Add d3_ex dependency
```

That's it! You're ready to build amazing D3 visualizations with LiveView. 🚀
