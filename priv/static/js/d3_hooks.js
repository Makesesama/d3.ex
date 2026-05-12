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
    if (!eventInput) {
      console.warn(`D3Ex: No input found for event "${eventName}"`);
      return;
    }

    const eventHandler = eventInput.value;
    if (!eventHandler) {
      console.warn(`D3Ex: No event handler name set for "${eventName}"`);
      return;
    }

    console.log(`D3Ex: Sending event "${eventHandler}" with payload:`, payload);

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
   * Subscribe to id-scoped LiveView events for streaming data updates.
   *
   * Subscribes to `${this.el.id}:${op}` for each key in the `handlers` map.
   * The hook receives only events targeted at its specific element id, so
   * multiple charts on the same page do not cross-talk.
   *
   * Server side, emit these via `D3Ex.Live.set_data/3`, `append/3`,
   * `patch/3`, `remove/3` (or the network-specific helpers).
   *
   * @param {object} handlers - Map of op name → handler function. Handlers
   *   are called as methods on `this`, so they can read/mutate hook state.
   */
  bindDataEvents(handlers) {
    const id = this.el.id;
    for (const op of Object.keys(handlers)) {
      this.handleEvent(`${id}:${op}`, (payload) => handlers[op].call(this, payload));
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

    // Id-scoped streaming events (server-side: D3Ex.Live.*)
    this.bindDataEvents({
      set_data: ({data}) => {
        this.nodes = data.nodes || [];
        this.links = data.links || [];
        this.updateGraph();
      },
      add_node: ({node}) => this.addNode(node),
      remove_node: ({id}) => this.removeNode(id),
      update_node: ({id, changes}) => this.updateNode(id, changes),
      add_link: ({link}) => this.addLink(link),
      remove_link: ({source, target}) => this.removeLink(source, target),
    });
  },

  updated() {
    // Data flows exclusively through D3Ex.Live id-scoped events after mount.
    // Only the `data-selected` scalar still updates via attribute diff.
    const newSelected = this.getSelected();

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
    this.linkGroup = this.g.append('g').attr('class', 'links');
    this.nodeGroup = this.g.append('g').attr('class', 'nodes');

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

    // Id-scoped streaming events (server-side: D3Ex.Live.*)
    this.bindDataEvents({
      set_data: ({data}) => { this.data = data; this.updateChart(); },
      append: ({items}) => { this.data = this.data.concat(items); this.updateChart(); },
      patch: ({changes}) => { this.applyPatch(changes); this.updateChart(); },
      remove: ({ids}) => { this.applyRemove(ids); this.updateChart(); },
    });
  },

  applyPatch(changes) {
    const idKey = this.config.x_key;
    for (const {key, changes: itemChanges} of changes) {
      const item = this.data.find(d => d[idKey] === key);
      if (item) Object.assign(item, itemChanges);
    }
  },

  applyRemove(ids) {
    const idKey = this.config.x_key;
    const drop = new Set(ids);
    this.data = this.data.filter(d => !drop.has(d[idKey]));
  },

  updated() {
    // Data flows exclusively through D3Ex.Live id-scoped events after mount.
    // Config and attribute changes are not currently mirrored — passing new
    // config requires a remount today; revisit if a real use case appears.
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

    // Merge enter and update selections
    const barsMerged = barsEnter.merge(bars);

    // Attach event handlers to the merged selection (before transition)
    barsMerged
      .on('click', (event, d) => {
        this.sendEvent('on_bar_click', d);
      })
      .on('mouseover', (event, d) => {
        d3.select(event.currentTarget).attr('opacity', 0.7);
        this.sendEvent('on_bar_hover', d);
      })
      .on('mouseout', (event, d) => {
        d3.select(event.currentTarget).attr('opacity', 1);
      });

    // Apply transitions
    barsMerged
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

    // Id-scoped streaming events (server-side: D3Ex.Live.*)
    this.bindDataEvents({
      set_data: ({data}) => { this.data = data; this.updateChart(); },
      append: ({items}) => { this.data = this.data.concat(items); this.updateChart(); },
      patch: ({changes}) => { this.applyPatch(changes); this.updateChart(); },
      remove: ({ids}) => { this.applyRemove(ids); this.updateChart(); },
    });
  },

  applyPatch(changes) {
    const idKey = this.config.x_key;
    for (const {key, changes: itemChanges} of changes) {
      const item = this.data.find(d => d[idKey] === key);
      if (item) Object.assign(item, itemChanges);
    }
  },

  applyRemove(ids) {
    const idKey = this.config.x_key;
    const drop = new Set(ids);
    this.data = this.data.filter(d => !drop.has(d[idKey]));
  },

  updated() {
    // Data flows exclusively through D3Ex.Live id-scoped events after mount.
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

      // Merge enter and update selections
      const pointsMerged = pointsEnter.merge(points);

      // Attach event handlers to the merged selection (before transition)
      pointsMerged
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
        });

      // Apply position/color transitions
      pointsMerged
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

/**
 * D3 Stream Hook
 *
 * Bridges Phoenix `stream/3` to a D3 line chart. The Elixir component renders
 * a hidden `<div phx-update="stream">` feed of `<div data-stream-item>` nodes;
 * this hook watches the feed via `MutationObserver` and re-renders D3 whenever
 * Phoenix mutates the list (insert / delete / reset).
 *
 * Server-side memory is bounded by `stream_insert(socket, :points, p, limit:
 * N)`; reconnect semantics come from Phoenix's stream protocol.
 *
 * v1 supports `renderer: "line"` only and numeric x/y values (data-*
 * attributes are strings, coerced via `Number()`).
 */
export const D3Stream = {
  mounted() {
    if (!window.d3) {
      console.error('D3.js is not loaded. Please include D3.js in your application.');
      return;
    }

    this.config = this.getConfig();
    this.data = this.readFeed();
    this.initChart();
    // renderChart is invoked at the end of initChart already.

    this.pendingFlush = false;
    this.observer = new MutationObserver(() => this.scheduleFlush());
    const feed = this.el.querySelector('[data-stream-feed]');
    if (feed) {
      this.observer.observe(feed, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['data-x', 'data-y', 'data-series']
      });
    }
  },

  updated() {
    // Outer wrapper attributes may change (e.g. data-config). The feed is
    // its own phx-update="stream" subtree and the SVG sits inside a
    // phx-update="ignore" sibling, so there's nothing to do here.
  },

  destroyed() {
    if (this.observer) this.observer.disconnect();
    this.cleanup();
  },

  ...D3Hook,

  readFeed() {
    const { x_key, y_key, series_key } = this.config;
    const nodes = this.el.querySelectorAll('[data-stream-item]');
    const out = new Array(nodes.length);
    for (let i = 0; i < nodes.length; i++) {
      const n = nodes[i];
      const item = {
        [x_key]: Number(n.dataset.x),
        [y_key]: Number(n.dataset.y)
      };
      if (series_key && n.dataset.series !== undefined && n.dataset.series !== '') {
        item[series_key] = n.dataset.series;
      }
      out[i] = item;
    }
    return out;
  },

  scheduleFlush() {
    if (this.pendingFlush) return;
    this.pendingFlush = true;
    queueMicrotask(() => {
      this.pendingFlush = false;
      this.data = this.readFeed();
      this.renderChart();
    });
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

    this.yAxis = this.g.append('g')
      .attr('class', 'y-axis');

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
        values: values.sort((a, b) => a[x_key] - b[x_key])
      }));
    } else {
      seriesData = [{
        key: 'default',
        values: this.data.slice().sort((a, b) => a[x_key] - b[x_key])
      }];
    }

    this.xScale.domain(d3.extent(this.data, d => d[x_key]));
    this.yScale.domain([
      d3.min(this.data, d => d[y_key]),
      d3.max(this.data, d => d[y_key])
    ]);

    this.xAxis.transition().duration(animation_duration)
      .call(d3.axisBottom(this.xScale));

    this.yAxis.transition().duration(animation_duration)
      .call(d3.axisLeft(this.yScale));

    if (this.config.show_grid) {
      this.xGrid.transition().duration(animation_duration)
        .call(d3.axisBottom(this.xScale).tickSize(-this.innerHeight).tickFormat(''));

      this.yGrid.transition().duration(animation_duration)
        .call(d3.axisLeft(this.yScale).tickSize(-this.innerWidth).tickFormat(''));
    }

    const curveTypes = {
      'linear': d3.curveLinear,
      'monotone': d3.curveMonotoneX,
      'step': d3.curveStep
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

    // Paths snap to the new shape instantly. D3's default `d` interpolator is
    // string-based and produces visual chaos when the vertex count changes
    // (which is every tick in a streaming chart). The smooth motion the eye
    // wants comes from the axis transition above + a short tick interval.
    if (show_area) {
      const areas = this.linesGroup
        .selectAll('.area')
        .data(seriesData, d => d.key);

      areas.exit().remove();

      areas.enter()
        .append('path')
        .attr('class', 'area')
        .attr('fill-opacity', 0.2)
        .merge(areas)
        .attr('d', d => area(d.values))
        .attr('fill', d => this.colorScale(d.key));
    }

    const lines = this.linesGroup
      .selectAll('.line')
      .data(seriesData, d => d.key);

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
  }
};

// Export default object for convenience
export default {
  D3Hook,
  D3NetworkGraph,
  D3BarChart,
  D3LineChart,
  D3Stream
};
