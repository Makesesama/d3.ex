/**
 * D3 Bar Chart hook — example component for the demo app.
 *
 * Animated bar chart with click and hover interactions. Pairs with
 * `D3ExDemoWeb.Components.Charts.BarChart`.
 *
 * Built on `createD3Hook` from the D3Ex library. The library itself ships only
 * the bridge primitives; this file is what an app developer would write.
 */

import { createD3Hook } from "../../../../../priv/static/js/d3_hooks.js";

export const D3BarChart = {
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

    this.xScale = d3.scaleBand()
      .range([0, this.innerWidth])
      .padding(this.config.bar_padding);

    this.yScale = d3.scaleLinear().range([this.innerHeight, 0]);

    this.colorScale = d3.scaleOrdinal(d3[this.config.color_scheme] || d3.schemeCategory10);

    this.xAxis = this.g.append('g')
      .attr('class', 'x-axis')
      .attr('transform', `translate(0,${this.innerHeight})`);

    this.yAxis = this.g.append('g').attr('class', 'y-axis');

    this.barsGroup = this.g.append('g').attr('class', 'bars');

    this.renderChart();
  },

  renderChart() {
    const d3 = window.d3;
    const { x_key, y_key, color_key, animation_duration } = this.config;

    this.xScale.domain(this.data.map(d => d[x_key]));
    this.yScale.domain([0, d3.max(this.data, d => d[y_key])]);

    this.xAxis.transition().duration(animation_duration).call(d3.axisBottom(this.xScale));
    this.yAxis.transition().duration(animation_duration).call(d3.axisLeft(this.yScale));

    const bars = this.barsGroup.selectAll('rect').data(this.data, d => d[x_key]);

    bars.exit()
      .transition()
      .duration(animation_duration)
      .attr('y', this.innerHeight)
      .attr('height', 0)
      .remove();

    const barsEnter = bars.enter()
      .append('rect')
      .attr('x', d => this.xScale(d[x_key]))
      .attr('y', this.innerHeight)
      .attr('width', this.xScale.bandwidth())
      .attr('height', 0)
      .attr('fill', d => color_key ? this.colorScale(d[color_key]) : 'steelblue')
      .style('cursor', 'pointer');

    const barsMerged = barsEnter.merge(bars);

    barsMerged
      .on('click', (event, d) => this.sendEvent('on_bar_click', d))
      .on('mouseover', (event, d) => {
        d3.select(event.currentTarget).attr('opacity', 0.7);
        this.sendEvent('on_bar_hover', d);
      })
      .on('mouseout', (event) => {
        d3.select(event.currentTarget).attr('opacity', 1);
      });

    barsMerged
      .transition()
      .duration(animation_duration)
      .attr('x', d => this.xScale(d[x_key]))
      .attr('y', d => this.yScale(d[y_key]))
      .attr('width', this.xScale.bandwidth())
      .attr('height', d => this.innerHeight - this.yScale(d[y_key]))
      .attr('fill', d => color_key ? this.colorScale(d[color_key]) : 'steelblue');
  },
};
