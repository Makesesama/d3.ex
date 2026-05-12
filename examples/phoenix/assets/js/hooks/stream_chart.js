/**
 * D3 Stream hook — example component for the demo app.
 *
 * Bridges Phoenix `stream/3` to a D3 line chart via `createStreamD3Hook`,
 * which handles the MutationObserver wiring on `[data-stream-feed]`. The
 * Elixir component renders a hidden `<div phx-update="stream">` feed of
 * `<div data-stream-item>` nodes; this hook just defines what to do when
 * `this.data` changes.
 *
 * Server-side memory is bounded by `stream_insert(socket, :points, p, limit:
 * N)`; reconnect semantics come from Phoenix's stream protocol.
 *
 * Numeric x/y only — the default `parseRow` coerces `data-x`/`data-y` via
 * `Number()`. For non-numeric data, pass a custom `parseRow` to
 * `createStreamD3Hook`.
 *
 * Pairs with `D3ExDemoWeb.Components.Charts.StreamChart`.
 */

import { createStreamD3Hook } from "../../../../../priv/static/js/d3_hooks.js";

export const D3Stream = {
  ...createStreamD3Hook({
    onMount()  { this.initChart() },
    onUpdate() { this.renderChart() },
  }),

  initChart() {
    const d3 = window.d3;
    const { width, height, margin } = this.config;

    this.svg = d3.select(this.el).select('svg');
    this.g = this.svg.append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);

    this.innerWidth = width - margin.left - margin.right;
    this.innerHeight = height - margin.top - margin.bottom;

    this.xScale = d3.scaleLinear().range([0, this.innerWidth]);
    this.yScale = d3.scaleLinear().range([this.innerHeight, 0]);
    this.colorScale = d3.scaleOrdinal(d3[this.config.color_scheme] || d3.schemeCategory10);

    this.xAxis = this.g.append('g')
      .attr('class', 'x-axis')
      .attr('transform', `translate(0,${this.innerHeight})`);

    this.yAxis = this.g.append('g').attr('class', 'y-axis');

    if (this.config.show_grid) {
      this.xGrid = this.g.append('g')
        .attr('class', 'grid x-grid')
        .style('stroke', '#e0e0e0')
        .style('stroke-opacity', 0.3);

      this.yGrid = this.g.append('g')
        .attr('class', 'grid y-grid')
        .style('stroke', '#e0e0e0')
        .style('stroke-opacity', 0.3);
    }

    this.linesGroup = this.g.append('g').attr('class', 'lines');
    this.pointsGroup = this.g.append('g').attr('class', 'points');

    this.renderChart();
  },

  renderChart() {
    const d3 = window.d3;
    const { x_key, y_key, series_key, curve_type, show_points, show_area, animation_duration } = this.config;

    if (this.data.length === 0) {
      this.linesGroup.selectAll('.line').remove();
      this.linesGroup.selectAll('.area').remove();
      this.pointsGroup.selectAll('circle').remove();
      return;
    }

    let seriesData;
    if (series_key) {
      const grouped = d3.group(this.data, d => d[series_key]);
      seriesData = Array.from(grouped, ([key, values]) => ({
        key,
        values: values.sort((a, b) => a[x_key] - b[x_key]),
      }));
    } else {
      seriesData = [{
        key: 'default',
        values: this.data.slice().sort((a, b) => a[x_key] - b[x_key]),
      }];
    }

    this.xScale.domain(d3.extent(this.data, d => d[x_key]));
    this.yScale.domain([
      d3.min(this.data, d => d[y_key]),
      d3.max(this.data, d => d[y_key]),
    ]);

    this.xAxis.transition().duration(animation_duration).call(d3.axisBottom(this.xScale));
    this.yAxis.transition().duration(animation_duration).call(d3.axisLeft(this.yScale));

    if (this.config.show_grid) {
      this.xGrid.transition().duration(animation_duration)
        .call(d3.axisBottom(this.xScale).tickSize(-this.innerHeight).tickFormat(''));

      this.yGrid.transition().duration(animation_duration)
        .call(d3.axisLeft(this.yScale).tickSize(-this.innerWidth).tickFormat(''));
    }

    const curveTypes = {
      'linear': d3.curveLinear,
      'monotone': d3.curveMonotoneX,
      'step': d3.curveStep,
    };

    const line = d3.line()
      .x(d => this.xScale(d[x_key]))
      .y(d => this.yScale(d[y_key]))
      .curve(curveTypes[curve_type] || d3.curveMonotoneX);

    let area;
    if (show_area) {
      area = d3.area()
        .x(d => this.xScale(d[x_key]))
        .y0(this.innerHeight)
        .y1(d => this.yScale(d[y_key]))
        .curve(curveTypes[curve_type] || d3.curveMonotoneX);
    }

    // Paths snap to the new shape instantly — D3's default `d` interpolator is
    // string-based and produces visual chaos when the vertex count changes
    // (which is every tick in a streaming chart). The smooth motion the eye
    // wants comes from the axis transition above + a short tick interval.
    if (show_area) {
      const areas = this.linesGroup.selectAll('.area').data(seriesData, d => d.key);
      areas.exit().remove();
      areas.enter()
        .append('path')
        .attr('class', 'area')
        .attr('fill-opacity', 0.2)
        .merge(areas)
        .attr('d', d => area(d.values))
        .attr('fill', d => this.colorScale(d.key));
    }

    const lines = this.linesGroup.selectAll('.line').data(seriesData, d => d.key);
    lines.exit().remove();

    lines.enter()
      .append('path')
      .attr('class', 'line')
      .attr('fill', 'none')
      .attr('stroke-width', 2)
      .merge(lines)
      .attr('d', d => line(d.values))
      .attr('stroke', d => this.colorScale(d.key));

    if (show_points) {
      const points = this.pointsGroup
        .selectAll('circle')
        .data(this.data, d => `${d[x_key]}-${d[y_key]}`);

      points.exit().remove();

      // Place new points at their correct (cx, cy) on enter — otherwise they
      // appear at the SVG origin and animate across the chart.
      points.enter()
        .append('circle')
        .attr('r', this.config.point_radius)
        .attr('stroke', '#fff')
        .attr('stroke-width', 1.5)
        .attr('cx', d => this.xScale(d[x_key]))
        .attr('cy', d => this.yScale(d[y_key]))
        .attr('fill', d => series_key ? this.colorScale(d[series_key]) : this.colorScale('default'))
        .merge(points)
        .attr('cx', d => this.xScale(d[x_key]))
        .attr('cy', d => this.yScale(d[y_key]))
        .attr('fill', d => series_key ? this.colorScale(d[series_key]) : this.colorScale('default'));
    }
  },
};
