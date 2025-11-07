# Contributing to D3Ex

Thank you for your interest in contributing to D3Ex! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful, inclusive, and professional in all interactions. We want D3Ex to be a welcoming project for everyone.

## Ways to Contribute

### 1. Report Bugs

If you find a bug, please open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- D3Ex version, Elixir version, Phoenix LiveView version
- Code sample if possible

### 2. Suggest Features

Have an idea for a new feature? Open an issue with:
- Clear description of the feature
- Use case / motivation
- Example API if applicable
- Willingness to implement it yourself

### 3. Submit Pull Requests

#### Before You Start

1. Check existing issues and PRs to avoid duplicates
2. For major changes, open an issue first to discuss
3. Make sure tests pass: `mix test`
4. Format your code: `mix format`

#### Development Setup

```bash
# Clone the repository
git clone https://github.com/Makesesama/d3.ex.git
cd d3.ex

# Install dependencies
mix deps.get

# Run tests
mix test

# Format code
mix format

# Generate docs
mix docs
```

#### PR Guidelines

1. **Branch Naming**: Use descriptive names
   - `feature/pie-chart-component`
   - `fix/network-graph-selection-bug`
   - `docs/improve-custom-component-guide`

2. **Commit Messages**: Write clear, concise messages
   - Use present tense ("Add feature" not "Added feature")
   - Reference issues: "Fix #123: Resolve network graph rendering issue"
   - Keep first line under 72 characters

3. **Code Style**:
   - Follow Elixir style guide
   - Run `mix format` before committing
   - Add typespecs for public functions
   - Write documentation for public APIs

4. **Tests**:
   - Add tests for new features
   - Update tests for bug fixes
   - Ensure all tests pass: `mix test`
   - Aim for good coverage

5. **Documentation**:
   - Update README.md if needed
   - Add @moduledoc and @doc for modules/functions
   - Update CHANGELOG.md
   - Add examples for new components

#### Creating a New Component

When contributing a new D3 visualization component:

1. **Elixir Module** (`lib/d3_ex/components/your_chart.ex`)
   - Use `D3Ex.Component`
   - Implement required callbacks
   - Add comprehensive @moduledoc with examples
   - Follow existing component patterns

2. **JavaScript Hook** (`priv/static/js/hooks/your_chart.js` or add to `d3_hooks.js`)
   - Extend `D3Hook` for utilities
   - Implement `mounted()`, `updated()`, `destroyed()`
   - Add event handlers
   - Document configuration options

3. **Tests** (`test/d3_ex/components/your_chart_test.exs`)
   - Test rendering with various configs
   - Test data encoding
   - Test event handlers
   - Test edge cases

4. **Example** (`examples/your_chart_live.ex`)
   - Create a LiveView example
   - Show common use cases
   - Demonstrate event handling
   - Include real-world scenario

5. **Documentation**
   - Update main README with new component
   - Add section to CUSTOM_COMPONENTS_GUIDE if novel pattern
   - Include in component comparison table

#### Example PR Structure

```
Add Sunburst Chart Component

- Implement D3Ex.Components.SunburstChart
- Add D3SunburstChart JavaScript hook
- Add comprehensive tests
- Add example LiveView
- Update README with component documentation

Closes #45
```

### 4. Improve Documentation

Documentation improvements are always welcome:
- Fix typos or unclear explanations
- Add more examples
- Improve API documentation
- Create tutorials or guides
- Add diagrams or visualizations

### 5. Share Your Components

Built a custom D3 component using D3Ex? Share it!
- Create a blog post
- Add to the community components wiki
- Submit as an example to the repo
- Present at meetups or conferences

## Component Design Principles

When contributing components, follow these principles:

### 1. Minimal State Synchronization
- Server manages: data, selections, saved state
- Client manages: visual state, animations, interactions
- Only sync essential state between server and client

### 2. Performance
- Throttle high-frequency events
- Support incremental updates
- Handle large datasets efficiently
- Use Canvas for >1000 elements

### 3. Flexibility
- Provide sensible defaults
- Allow configuration overrides
- Support event handlers
- Enable customization

### 4. Consistency
- Follow naming conventions
- Use similar patterns to existing components
- Maintain consistent API design
- Document thoroughly

### 5. Accessibility
- Add ARIA labels where appropriate
- Support keyboard navigation
- Provide text alternatives
- Consider screen readers

## Testing

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/d3_ex/component_test.exs

# Run with coverage
mix test --cover

# Run in watch mode (requires mix_test_watch)
mix test.watch
```

### Writing Tests

```elixir
defmodule D3Ex.Components.MyChartTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest
  import D3Ex.Components.MyChart

  describe "my_chart component" do
    test "renders with basic data" do
      assigns = %{id: "chart", data: [...]}
      result = rendered_to_string(my_chart(assigns))

      assert result =~ "expected output"
    end

    test "handles event callbacks" do
      assigns = %{
        id: "chart",
        data: [...],
        on_click: "item_clicked"
      }

      result = rendered_to_string(my_chart(assigns))
      assert result =~ "on_click"
    end
  end
end
```

## Documentation

### Writing Good Docs

1. **Module Documentation** (@moduledoc):
   - What the component does
   - When to use it
   - Basic example
   - Configuration options
   - Event handlers

2. **Function Documentation** (@doc):
   - What the function does
   - Parameters and types
   - Return value
   - Examples

3. **Examples**:
   - Show common use cases
   - Include data format examples
   - Demonstrate event handling
   - Keep examples realistic

### Example Documentation

```elixir
defmodule D3Ex.Components.AwesomeChart do
  @moduledoc """
  An awesome chart component that visualizes awesome data.

  ## Features
  - Feature 1
  - Feature 2

  ## Example

      <.awesome_chart
        id="my-chart"
        data={@awesome_data}
        on_click="item_clicked"
      />

  ## Data Format

  Data should be a list of maps:

      [
        %{x: 1, y: 2, label: "Point 1"},
        %{x: 2, y: 4, label: "Point 2"}
      ]

  ## Options

  - `data` - Chart data (required)
  - `on_click` - Click event handler
  - `width` - Chart width (default: 600)
  """

  @doc """
  Renders the awesome chart component.

  ## Options

    * `:data` - The data to visualize (required)
    * `:width` - Chart width in pixels (default: 600)
    * `:height` - Chart height in pixels (default: 400)

  ## Examples

      iex> assigns = %{id: "chart", data: [...]}
      iex> awesome_chart(assigns)
  """
  def awesome_chart(assigns) do
    # ...
  end
end
```

## Release Process

(For maintainers)

1. Update version in `mix.exs`
2. Update CHANGELOG.md
3. Run tests: `mix test`
4. Build docs: `mix docs`
5. Commit changes: `git commit -am "Release vX.Y.Z"`
6. Tag release: `git tag vX.Y.Z`
7. Push: `git push && git push --tags`
8. Publish to Hex: `mix hex.publish`

## Questions?

- Open an issue for questions about development
- Check existing issues and discussions
- Review the documentation and examples
- Reach out to maintainers

## Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Credited in release notes
- Added to contributors list
- Thanked profusely! 🙏

Thank you for contributing to D3Ex!
