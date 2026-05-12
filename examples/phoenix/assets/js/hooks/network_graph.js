/**
 * D3 Network Graph hook — example component for the demo app.
 *
 * Force-directed network graph with interactive nodes and links. Pairs with
 * `D3ExDemoWeb.Components.Charts.NetworkGraph`.
 *
 * Built on `createD3Hook` from the D3Ex library. The library itself ships only
 * the bridge primitives; this file is what an app developer would write.
 */

import { createD3Hook } from "../../../../../priv/static/js/d3_hooks.js";

export const D3NetworkGraph = {
  ...createD3Hook({
    onMount() {
      this.nodes = this.getData();
      this.links = this.getLinks();
      this.selected = this.getSelected();
      this.initGraph();
    },
    onUpdated() {
      // Only the `data-selected` scalar updates via attribute diff;
      // node/link data flows through the id-scoped events below.
      const newSelected = this.getSelected();
      if (newSelected !== this.selected) {
        this.selected = newSelected;
        this.updateSelection();
      }
    },
    events: {
      set_data({ data }) {
        this.nodes = data.nodes || [];
        this.links = data.links || [];
        this.updateGraph();
      },
      add_node({ node })              { this.addNode(node); },
      remove_node({ id })             { this.removeNode(id); },
      update_node({ id, changes })    { this.updateNode(id, changes); },
      add_link({ link })              { this.addLink(link); },
      remove_link({ source, target }) { this.removeLink(source, target); },
    },
  }),

  initGraph() {
    const d3 = window.d3;
    const { width, height, charge_strength, link_distance, enable_zoom, collision_radius, center_force } = this.config;

    this.svg = d3.select(this.el).select('svg');

    if (enable_zoom) {
      const zoom = d3.zoom()
        .scaleExtent([0.1, 10])
        .on('zoom', (event) => this.g.attr('transform', event.transform));
      this.svg.call(zoom);
    }

    this.g = this.svg.append('g');
    this.linkGroup = this.g.append('g').attr('class', 'links');
    this.nodeGroup = this.g.append('g').attr('class', 'nodes');

    this.simulation = d3.forceSimulation(this.nodes)
      .force('link', d3.forceLink(this.links).id(d => d.id).distance(link_distance))
      .force('charge', d3.forceManyBody().strength(charge_strength))
      .force('center', d3.forceCenter(width / 2, height / 2).strength(center_force))
      .force('collision', d3.forceCollide().radius(collision_radius));

    this.colorScale = d3.scaleOrdinal(d3[this.config.color_scheme] || d3.schemeCategory10);

    this.renderGraph();
  },

  renderGraph() {
    const d3 = window.d3;
    const { node_radius, enable_drag } = this.config;

    const link = this.linkGroup
      .selectAll('line')
      .data(this.links, d => `${d.source.id || d.source}-${d.target.id || d.target}`);

    link.exit().remove();

    const linkEnter = link.enter()
      .append('line')
      .attr('stroke', '#999')
      .attr('stroke-opacity', 0.6)
      .attr('stroke-width', d => Math.sqrt(d.value || 1));

    this.linkElements = linkEnter.merge(link);

    const node = this.nodeGroup
      .selectAll('g')
      .data(this.nodes, d => d.id);

    node.exit().remove();

    const nodeEnter = node.enter()
      .append('g')
      .attr('cursor', 'pointer');

    nodeEnter.append('circle')
      .attr('r', node_radius)
      .attr('fill', d => this.colorScale(d.group || 0))
      .attr('stroke', '#fff')
      .attr('stroke-width', 1.5);

    nodeEnter.append('text')
      .attr('dx', node_radius + 5)
      .attr('dy', '.35em')
      .text(d => d.label || d.id)
      .style('font-size', '10px')
      .style('pointer-events', 'none');

    this.nodeElements = nodeEnter.merge(node);

    if (enable_drag) {
      const drag = d3.drag()
        .on('start', (event, d) => {
          if (!event.active) this.simulation.alphaTarget(0.3).restart();
          d.fx = d.x;
          d.fy = d.y;
        })
        .on('drag', (event, d) => {
          d.fx = event.x;
          d.fy = event.y;
        })
        .on('end', (event, d) => {
          if (!event.active) this.simulation.alphaTarget(0);
          d.fx = null;
          d.fy = null;
          this.sendEvent('on_position_save', { id: d.id, x: d.x, y: d.y });
        });

      this.nodeElements.call(drag);
    }

    this.nodeElements.on('click', (event, d) => {
      event.stopPropagation();
      this.sendEvent('on_select', { id: d.id });
    });

    this.updateSelection();

    this.simulation.on('tick', () => {
      this.linkElements
        .attr('x1', d => d.source.x)
        .attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x)
        .attr('y2', d => d.target.y);

      this.nodeElements
        .attr('transform', d => `translate(${d.x},${d.y})`);
    });
  },

  updateGraph() {
    this.simulation.nodes(this.nodes);
    this.simulation.force('link').links(this.links);
    this.renderGraph();
    this.simulation.alpha(0.3).restart();
  },

  updateSelection() {
    if (!this.nodeElements) return;

    this.nodeElements.selectAll('circle')
      .attr('stroke', d => d.id === this.selected ? '#ff0000' : '#fff')
      .attr('stroke-width', d => d.id === this.selected ? 3 : 1.5);
  },

  addNode(node) {
    this.nodes.push(node);
    this.updateGraph();
  },

  removeNode(id) {
    this.nodes = this.nodes.filter(n => n.id !== id);
    this.links = this.links.filter(l =>
      (l.source.id || l.source) !== id && (l.target.id || l.target) !== id
    );
    this.updateGraph();
  },

  updateNode(id, changes) {
    const node = this.nodes.find(n => n.id === id);
    if (node) {
      Object.assign(node, changes);
      this.updateGraph();
    }
  },

  addLink(link) {
    this.links.push(link);
    this.updateGraph();
  },

  removeLink(source, target) {
    this.links = this.links.filter(l =>
      !((l.source.id || l.source) === source && (l.target.id || l.target) === target)
    );
    this.updateGraph();
  },
};
