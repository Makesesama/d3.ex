# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-07

### Added
- Initial release of D3Ex
- Core `D3Ex.Component` behavior for building custom D3 visualizations
- `D3Ex.Components.NetworkGraph` - Force-directed network graphs
- `D3Ex.Components.BarChart` - Animated bar charts
- `D3Ex.Components.LineChart` - Multi-line time series charts
- JavaScript hooks for seamless LiveView integration
- Minimal state synchronization architecture
- Comprehensive documentation and examples
- Example LiveView applications:
  - Network graph with selection and drag
  - Real-time dashboard with multiple charts
  - Custom component building guide
- Test suite with component tests
- MIT License

### Features
- **Performance**: Minimal WebSocket traffic using thin server, rich client model
- **Extensibility**: Easy-to-use component pattern for custom visualizations
- **Real-time**: LiveView integration for instant data synchronization
- **Interactive**: Support for clicks, drags, zooms, and custom events
- **Configurable**: Sensible defaults with full customization options

[Unreleased]: https://github.com/Makesesama/d3.ex/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Makesesama/d3.ex/releases/tag/v0.1.0
