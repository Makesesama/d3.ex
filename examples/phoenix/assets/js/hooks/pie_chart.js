import { createD3Hook } from "../../../../../priv/static/js/d3_hooks.js";

/**
 * D3PieChart — demo hook for `D3ExDemoWeb.Components.PieChart`.
 *
 * The `createD3Hook` factory provides the LiveView lifecycle (D3 readiness
 * check, config parsing, id-scoped event binding, cleanup); we only write
 * the D3 — pie layout, arc render, slice click. The whole hook below is
 * roughly the same size as the D3 code that does the work, which is the
 * point of the factory.
 */
export const D3PieChart = {
  ...createD3Hook({
    onMount() {
      this.data = this.getData();
      this.initChart();
    },
    events: {
      // Server emits via `D3Ex.Live.set_data(socket, "pie", new_data)`.
      set_data({ data }) {
        this.data = data;
        this.renderChart();
      },
    },
  }),

  initChart() {
    const d3 = window.d3;
    const { width, height, inner_radius, outer_radius, color_scheme } = this.config;

    this.svg = d3.select(this.el).select("svg");
    this.g = this.svg.append("g")
      .attr("transform", `translate(${width / 2}, ${height / 2})`);

    this.pie = d3.pie().value(d => d[this.config.value_key]).sort(null);
    this.arc = d3.arc().innerRadius(inner_radius).outerRadius(outer_radius);
    this.labelArc = d3.arc()
      .innerRadius(outer_radius * 0.7)
      .outerRadius(outer_radius * 0.7);

    this.color = d3.scaleOrdinal(d3[color_scheme] || d3.schemeCategory10);

    this.renderChart();
  },

  renderChart() {
    const d3 = window.d3;
    const { label_key, animation_duration } = this.config;

    // Slices
    const arcs = this.g.selectAll(".arc")
      .data(this.pie(this.data), d => d.data[label_key]);

    arcs.exit().remove();

    const arcEnter = arcs.enter().append("g").attr("class", "arc");

    arcEnter.append("path")
      .attr("fill", d => this.color(d.data[label_key]))
      .attr("stroke", "#fff")
      .attr("stroke-width", 2)
      .style("cursor", "pointer")
      .on("click", (event, d) => this.sendEvent("on_slice_click", d.data))
      .each(function (d) { this._current = d; });

    const arcMerged = arcEnter.merge(arcs);

    // Tween paths between layouts so transitions look like a pie morph,
    // not a snap. Without `_current`, d3 has no "previous" state to
    // interpolate from after a `set_data`.
    arcMerged.select("path")
      .transition().duration(animation_duration)
      .attrTween("d", (d, i, nodes) => {
        const node = nodes[i];
        const interpolate = d3.interpolate(node._current || d, d);
        node._current = interpolate(1);
        return t => this.arc(interpolate(t));
      });

    // Labels
    const labels = this.g.selectAll(".label")
      .data(this.pie(this.data), d => d.data[label_key]);

    labels.exit().remove();

    labels.enter()
      .append("text")
      .attr("class", "label")
      .attr("text-anchor", "middle")
      .style("font-size", "12px")
      .style("pointer-events", "none")
      .merge(labels)
      .attr("transform", d => `translate(${this.labelArc.centroid(d)})`)
      .text(d => d.data[label_key]);
  },
};
