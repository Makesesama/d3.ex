/**
 * D3 Line Chart hook — example component for the demo app.
 *
 * Multi-line chart with interactive points and tooltips. Pairs with
 * `D3ExDemoWeb.Components.Charts.LineChart`.
 *
 * Built on `createD3Hook` from the D3Ex library. The library itself ships only
 * the bridge primitives; this file is what an app developer would write.
 */

import { createD3Hook } from "../../../../priv/static/js/d3_hooks.js";

export const D3LineChart = {
  ...createD3Hook({
    onMount() {
      this.data = this.getData();
      this.initChart();
    },
    events: {
      set_data({ data })  { this.data = data;                    this.renderChart(); },
      append({ items })   { this.data = this.data.concat(items); this.renderChart(); },
      patch({ changes })  { this.applyPatch(changes);            this.renderChart(); },
      remove({ ids })     { this.applyRemove(ids);               this.renderChart(); },
    },
  }),

  applyPatch(changes) {
    const idKey = this.config.x_key;
    for (const { key, changes: itemChanges } of changes) {
      const item = this.data.find(d => d[idKey] === key);
      if (item) Object.assign(item, itemChanges);
    }
  },

  applyRemove(ids) {
    const idKey = this.config.x_key;
    const drop = new Set(ids);
    this.data = this.data.filter(d => !drop.has(d[idKey]));
  },

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
    this.yScale.domain([0, d3.max(this.data, d => d[y_key])]);

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

      const areas = this.linesGroup.selectAll('.area').data(seriesData, d => d.key);
      areas.exit().remove();

      const areasEnter = areas.enter()
        .append('path')
        .attr('class', 'area')
        .attr('fill-opacity', 0.2);

      areasEnter.merge(areas)
        .transition()
        .duration(animation_duration)
        .attr('d', d => area(d.values))
        .attr('fill', d => this.colorScale(d.key));
    }

    const lines = this.linesGroup.selectAll('.line').data(seriesData, d => d.key);
    lines.exit().remove();

    const linesEnter = lines.enter()
      .append('path')
      .attr('class', 'line')
      .attr('fill', 'none')
      .attr('stroke-width', 2);

    linesEnter.merge(lines)
      .transition()
      .duration(animation_duration)
      .attr('d', d => line(d.values))
      .attr('stroke', d => this.colorScale(d.key));

    if (show_points) {
      const points = this.pointsGroup
        .selectAll('circle')
        .data(this.data, (d, i) => `${d[x_key]}-${d[y_key]}-${i}`);

      points.exit().remove();

      const pointsEnter = points.enter()
        .append('circle')
        .attr('r', this.config.point_radius)
        .attr('stroke', '#fff')
        .attr('stroke-width', 1.5)
        .style('cursor', 'pointer');

      const pointsMerged = pointsEnter.merge(points);

      pointsMerged
        .on('click', (event, d) => this.sendEvent('on_point_click', d))
        .on('mouseover', (event) => {
          d3.select(event.currentTarget)
            .transition()
            .duration(150)
            .attr('r', this.config.point_radius * 1.5);
        })
        .on('mouseout', (event) => {
          d3.select(event.currentTarget)
            .transition()
            .duration(150)
            .attr('r', this.config.point_radius);
        });

      pointsMerged
        .transition()
        .duration(animation_duration)
        .attr('cx', d => this.xScale(d[x_key]))
        .attr('cy', d => this.yScale(d[y_key]))
        .attr('fill', d => series_key ? this.colorScale(d[series_key]) : this.colorScale('default'));
    }
  },
};
