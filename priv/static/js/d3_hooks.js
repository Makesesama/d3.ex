/**
 * D3Ex - D3.js Hooks for Phoenix LiveView
 *
 * Provides LiveView hooks for D3.js visualizations with minimal state synchronization.
 */

/**
 * Base D3 Hook with common utilities
 *
 * All D3 hooks inherit these helper methods for consistent behavior.
 */
export const D3Hook = {
  /**
   * Get parsed configuration from data-config attribute
   */
  getConfig() {
    const configAttr = this.el.getAttribute('data-config');
    return configAttr ? JSON.parse(configAttr) : {};
  },

  /**
   * Get parsed data from data-items or data-nodes attribute
   */
  getData() {
    const itemsAttr = this.el.getAttribute('data-items');
    const nodesAttr = this.el.getAttribute('data-nodes');
    const dataAttr = itemsAttr || nodesAttr;
    return dataAttr ? JSON.parse(dataAttr) : [];
  },

  /**
   * Get parsed links data (for network graphs)
   */
  getLinks() {
    const linksAttr = this.el.getAttribute('data-links');
    return linksAttr ? JSON.parse(linksAttr) : [];
  },

  /**
   * Get selected node/item ID
   */
  getSelected() {
    return this.el.getAttribute('data-selected');
  },

  /**
   * Send event to LiveView server
   *
   * @param {string} eventName - Name of the event handler (e.g., 'on_select')
   * @param {object} payload - Event payload
   * @param {number} throttle - Optional throttle delay in ms
   */
  sendEvent(eventName, payload, throttle = 0) {
    const eventInput = this.el.querySelector(`input[name="${eventName}"]`);
    if (!eventInput) return;

    const eventHandler = eventInput.value;
    if (!eventHandler) return;

    if (throttle > 0) {
      if (this.throttleTimers && this.throttleTimers[eventName]) {
        clearTimeout(this.throttleTimers[eventName]);
      }
      if (!this.throttleTimers) this.throttleTimers = {};

      this.throttleTimers[eventName] = setTimeout(() => {
        this.pushEvent(eventHandler, payload);
      }, throttle);
    } else {
      this.pushEvent(eventHandler, payload);
    }
  },

  /**
   * Clean up resources
   */
  cleanup() {
    if (this.simulation) {
      this.simulation.stop();
    }
    if (this.throttleTimers) {
      Object.values(this.throttleTimers).forEach(timer => clearTimeout(timer));
    }
  }
};

/**
 * D3 Network Graph Hook
 *
 * Force-directed network graph with interactive nodes and links.
 */
export const D3NetworkGraph = {
  mounted() {
    if (!window.d3) {
      console.error('D3.js is not loaded. Please include D3.js in your application.');
      return;
    }

    this.config = this.getConfig();
    this.nodes = this.getData();
    this.links = this.getLinks();
    this.selected = this.getSelected();

    this.initGraph();

    // Listen for incremental updates
    this.handleEvent('graph:add_node', ({node}) => this.addNode(node));
    this.handleEvent('graph:remove_node', ({id}) => this.removeNode(id));
    this.handleEvent('graph:update_node', ({id, changes}) => this.updateNode(id, changes));
    this.handleEvent('graph:add_link', ({link}) => this.addLink(link));
    this.handleEvent('graph:remove_link', ({source, target}) => this.removeLink(source, target));
  },

  updated() {
    // Handle data updates from server
    const newNodes = this.getData();
    const newLinks = this.getLinks();
    const newSelected = this.getSelected();

    if (JSON.stringify(newNodes) !== JSON.stringify(this.nodes) ||
        JSON.stringify(newLinks) !== JSON.stringify(this.links)) {
      this.nodes = newNodes;
      this.links = newLinks;
      this.updateGraph();
    }

    if (newSelected !== this.selected) {
      this.selected = newSelected;
      this.updateSelection();
    }
  },

  destroyed() {
    this.cleanup();
  },

  ...D3Hook,

  initGraph() {
    const d3 = window.d3;
    const { width, height, charge_strength, link_distance, enable_zoom, enable_drag, collision_radius, center_force } = this.config;

    // Create SVG and groups
    this.svg = d3.select(this.el).select('svg');

    // Add zoom behavior
    if (enable_zoom) {
      const zoom = d3.zoom()
        .scaleExtent([0.1, 10])
        .on('zoom', (event) => {
          this.g.attr('transform', event.transform);
        });
      this.svg.call(zoom);
    }

    this.g = this.svg.append('g');
    this.linkGroup = this.g.select('.links');
    this.nodeGroup = this.g.select('.nodes');

    // Create force simulation
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

    // Render links
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

    // Render nodes
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

    // Add drag behavior
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

          // Send position update to server
          this.sendEvent('on_position_save', {
            id: d.id,
            x: d.x,
            y: d.y
          });
        });

      this.nodeElements.call(drag);
    }

    // Add click handler for selection
    this.nodeElements.on('click', (event, d) => {
      event.stopPropagation();
      this.sendEvent('on_select', { id: d.id });
    });

    // Update selection
    this.updateSelection();

    // Update positions on simulation tick
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
    // Update simulation with new data
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

  // Incremental update methods
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
  }
};

/**
 * D3 Bar Chart Hook
 *
 * Animated bar chart with click and hover interactions.
 */
export const D3BarChart = {
  mounted() {
    if (!window.d3) {
      console.error('D3.js is not loaded. Please include D3.js in your application.');
      return;
    }

    this.config = this.getConfig();
    this.data = this.getData();

    this.initChart();
  },

  updated() {
    const newData = this.getData();
    if (JSON.stringify(newData) !== JSON.stringify(this.data)) {
      this.data = newData;
      this.updateChart();
    }
  },

  destroyed() {
    this.cleanup();
  },

  ...D3Hook,

  initChart() {
    const d3 = window.d3;
    const { width, height, margin, x_key, y_key, color_key } = this.config;

    this.svg = d3.select(this.el).select('svg');
    this.g = this.svg.append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);

    this.innerWidth = width - margin.left - margin.right;
    this.innerHeight = height - margin.top - margin.bottom;

    // Create scales
    this.xScale = d3.scaleBand()
      .range([0, this.innerWidth])
      .padding(this.config.bar_padding);

    this.yScale = d3.scaleLinear()
      .range([this.innerHeight, 0]);

    this.colorScale = d3.scaleOrdinal(d3[this.config.color_scheme] || d3.schemeCategory10);

    // Create axes
    this.xAxis = this.g.append('g')
      .attr('class', 'x-axis')
      .attr('transform', `translate(0,${this.innerHeight})`);

    this.yAxis = this.g.append('g')
      .attr('class', 'y-axis');

    // Create bars container
    this.barsGroup = this.g.append('g')
      .attr('class', 'bars');

    this.renderChart();
  },

  renderChart() {
    const d3 = window.d3;
    const { x_key, y_key, color_key, animation_duration } = this.config;

    // Update scales
    this.xScale.domain(this.data.map(d => d[x_key]));
    this.yScale.domain([0, d3.max(this.data, d => d[y_key])]);

    // Update axes
    this.xAxis.transition().duration(animation_duration)
      .call(d3.axisBottom(this.xScale));

    this.yAxis.transition().duration(animation_duration)
      .call(d3.axisLeft(this.yScale));

    // Update bars
    const bars = this.barsGroup
      .selectAll('rect')
      .data(this.data, d => d[x_key]);

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

    barsEnter.merge(bars)
      .on('click', (event, d) => {
        this.sendEvent('on_bar_click', d);
      })
      .on('mouseover', (event, d) => {
        d3.select(event.currentTarget).attr('opacity', 0.7);
        this.sendEvent('on_bar_hover', d);
      })
      .on('mouseout', (event, d) => {
        d3.select(event.currentTarget).attr('opacity', 1);
      })
      .transition()
      .duration(animation_duration)
      .attr('x', d => this.xScale(d[x_key]))
      .attr('y', d => this.yScale(d[y_key]))
      .attr('width', this.xScale.bandwidth())
      .attr('height', d => this.innerHeight - this.yScale(d[y_key]))
      .attr('fill', d => color_key ? this.colorScale(d[color_key]) : 'steelblue');
  },

  updateChart() {
    this.renderChart();
  }
};

/**
 * D3 Line Chart Hook
 *
 * Multi-line chart with interactive points and tooltips.
 */
export const D3LineChart = {
  mounted() {
    if (!window.d3) {
      console.error('D3.js is not loaded. Please include D3.js in your application.');
      return;
    }

    this.config = this.getConfig();
    this.data = this.getData();

    this.initChart();
  },

  updated() {
    const newData = this.getData();
    if (JSON.stringify(newData) !== JSON.stringify(this.data)) {
      this.data = newData;
      this.updateChart();
    }
  },

  destroyed() {
    this.cleanup();
  },

  ...D3Hook,

  initChart() {
    const d3 = window.d3;
    const { width, height, margin } = this.config;

    this.svg = d3.select(this.el).select('svg');
    this.g = this.svg.append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);

    this.innerWidth = width - margin.left - margin.right;
    this.innerHeight = height - margin.top - margin.bottom;

    // Create scales
    this.xScale = d3.scaleLinear()
      .range([0, this.innerWidth]);

    this.yScale = d3.scaleLinear()
      .range([this.innerHeight, 0]);

    this.colorScale = d3.scaleOrdinal(d3[this.config.color_scheme] || d3.schemeCategory10);

    // Create axes
    this.xAxis = this.g.append('g')
      .attr('class', 'x-axis')
      .attr('transform', `translate(0,${this.innerHeight})`);

    this.yAxis = this.g.append('g')
      .attr('class', 'y-axis');

    // Create grid
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

    // Create lines container
    this.linesGroup = this.g.append('g')
      .attr('class', 'lines');

    // Create points container
    this.pointsGroup = this.g.append('g')
      .attr('class', 'points');

    this.renderChart();
  },

  renderChart() {
    const d3 = window.d3;
    const { x_key, y_key, series_key, curve_type, show_points, show_area, animation_duration } = this.config;

    // Group data by series if series_key is provided
    let seriesData;
    if (series_key) {
      const grouped = d3.group(this.data, d => d[series_key]);
      seriesData = Array.from(grouped, ([key, values]) => ({
        key,
        values: values.sort((a, b) => a[x_key] - b[x_key])
      }));
    } else {
      seriesData = [{
        key: 'default',
        values: this.data.sort((a, b) => a[x_key] - b[x_key])
      }];
    }

    // Update scales
    const allValues = this.data.flatMap(d => [d[x_key], d[y_key]]);
    this.xScale.domain(d3.extent(this.data, d => d[x_key]));
    this.yScale.domain([0, d3.max(this.data, d => d[y_key])]);

    // Update axes
    this.xAxis.transition().duration(animation_duration)
      .call(d3.axisBottom(this.xScale));

    this.yAxis.transition().duration(animation_duration)
      .call(d3.axisLeft(this.yScale));

    // Update grid
    if (this.config.show_grid) {
      this.xGrid.transition().duration(animation_duration)
        .call(d3.axisBottom(this.xScale).tickSize(-this.innerHeight).tickFormat(''));

      this.yGrid.transition().duration(animation_duration)
        .call(d3.axisLeft(this.yScale).tickSize(-this.innerWidth).tickFormat(''));
    }

    // Create line generator
    const curveTypes = {
      'linear': d3.curveLinear,
      'monotone': d3.curveMonotoneX,
      'step': d3.curveStep
    };

    const line = d3.line()
      .x(d => this.xScale(d[x_key]))
      .y(d => this.yScale(d[y_key]))
      .curve(curveTypes[curve_type] || d3.curveMonotoneX);

    // Create area generator if needed
    let area;
    if (show_area) {
      area = d3.area()
        .x(d => this.xScale(d[x_key]))
        .y0(this.innerHeight)
        .y1(d => this.yScale(d[y_key]))
        .curve(curveTypes[curve_type] || d3.curveMonotoneX);
    }

    // Render areas (if enabled)
    if (show_area) {
      const areas = this.linesGroup
        .selectAll('.area')
        .data(seriesData, d => d.key);

      areas.exit().remove();

      const areasEnter = areas.enter()
        .append('path')
        .attr('class', 'area')
        .attr('fill', d => this.colorScale(d.key))
        .attr('fill-opacity', 0.2);

      areasEnter.merge(areas)
        .transition()
        .duration(animation_duration)
        .attr('d', d => area(d.values))
        .attr('fill', d => this.colorScale(d.key));
    }

    // Render lines
    const lines = this.linesGroup
      .selectAll('.line')
      .data(seriesData, d => d.key);

    lines.exit().remove();

    const linesEnter = lines.enter()
      .append('path')
      .attr('class', 'line')
      .attr('fill', 'none')
      .attr('stroke', d => this.colorScale(d.key))
      .attr('stroke-width', 2);

    linesEnter.merge(lines)
      .transition()
      .duration(animation_duration)
      .attr('d', d => line(d.values))
      .attr('stroke', d => this.colorScale(d.key));

    // Render points (if enabled)
    if (show_points) {
      const points = this.pointsGroup
        .selectAll('circle')
        .data(this.data, (d, i) => `${d[x_key]}-${d[y_key]}-${i}`);

      points.exit().remove();

      const pointsEnter = points.enter()
        .append('circle')
        .attr('r', this.config.point_radius)
        .attr('fill', d => series_key ? this.colorScale(d[series_key]) : this.colorScale('default'))
        .attr('stroke', '#fff')
        .attr('stroke-width', 1.5)
        .style('cursor', 'pointer');

      pointsEnter.merge(points)
        .on('click', (event, d) => {
          this.sendEvent('on_point_click', d);
        })
        .on('mouseover', (event, d) => {
          d3.select(event.currentTarget)
            .transition()
            .duration(150)
            .attr('r', this.config.point_radius * 1.5);
        })
        .on('mouseout', (event, d) => {
          d3.select(event.currentTarget)
            .transition()
            .duration(150)
            .attr('r', this.config.point_radius);
        })
        .transition()
        .duration(animation_duration)
        .attr('cx', d => this.xScale(d[x_key]))
        .attr('cy', d => this.yScale(d[y_key]))
        .attr('fill', d => series_key ? this.colorScale(d[series_key]) : this.colorScale('default'));
    }
  },

  updateChart() {
    this.renderChart();
  }
};

// Export default object for convenience
export default {
  D3Hook,
  D3NetworkGraph,
  D3BarChart,
  D3LineChart
};
