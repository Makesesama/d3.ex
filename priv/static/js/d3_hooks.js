/**
 * D3Ex — D3.js × Phoenix LiveView bridge primitives.
 *
 * Two exports:
 *
 *   - `D3Hook`         A mixin of helpers (getConfig, getData, sendEvent,
 *                      bindDataEvents, cleanup) that you can spread into a
 *                      hook object you write by hand.
 *
 *   - `createD3Hook`   A factory that bundles the lifecycle (mounted /
 *                      updated / destroyed), config + events parsing, and
 *                      id-scoped event subscription so you only write the
 *                      D3-specific parts.
 *
 * The library ships no chart implementations. See `examples/phoenix` for
 * sample hooks (bar/line/network/stream) built on these primitives.
 */

/**
 * Helper mixin. Methods read `this.el.dataset.*` and call `this.pushEvent`,
 * so they only make sense bound to a Phoenix hook (or anything with the same
 * shape).
 */
export const D3Hook = {
  /** Parse `data-config` into an object. */
  getConfig() {
    const attr = this.el.getAttribute('data-config');
    return attr ? JSON.parse(attr) : {};
  },

  /** Parse `data-items` or `data-nodes` into an array. */
  getData() {
    const attr = this.el.getAttribute('data-items') || this.el.getAttribute('data-nodes');
    return attr ? JSON.parse(attr) : [];
  },

  /** Parse `data-links` into an array (for network graphs). */
  getLinks() {
    const attr = this.el.getAttribute('data-links');
    return attr ? JSON.parse(attr) : [];
  },

  /** Read `data-selected` scalar. */
  getSelected() {
    return this.el.getAttribute('data-selected');
  },

  /**
   * Parse `data-events` into a `{slot → handler}` map. Slots are component
   * names (e.g. `'on_bar_click'`); handlers are LiveView event names
   * (e.g. `'bar_clicked'`). Returns `{}` if absent.
   */
  getEvents() {
    const attr = this.el.getAttribute('data-events');
    return attr ? JSON.parse(attr) : {};
  },

  /**
   * Push an event to the LiveView, looked up by slot name. Silently no-ops
   * when the component didn't wire up that slot — interactions that fire on
   * every drag/hover shouldn't spam the console.
   *
   * @param {string} eventName Slot name on the component (e.g. 'on_select')
   * @param {object} payload   Event payload
   * @param {number} throttle  Optional throttle delay in ms
   */
  sendEvent(eventName, payload, throttle = 0) {
    // Memoize on first send so hooks that spread `...D3Hook` without going
    // through `createD3Hook` still work — they get `this.events` populated
    // lazily instead of in `mounted`.
    const events = this.events || (this.events = this.getEvents());
    const handler = events[eventName];
    if (!handler) return;

    if (throttle > 0) {
      if (this.throttleTimers && this.throttleTimers[eventName]) {
        clearTimeout(this.throttleTimers[eventName]);
      }
      if (!this.throttleTimers) this.throttleTimers = {};

      this.throttleTimers[eventName] = setTimeout(() => {
        this.pushEvent(handler, payload);
      }, throttle);
    } else {
      this.pushEvent(handler, payload);
    }
  },

  /**
   * Subscribe to id-scoped LiveView events for streaming data updates.
   *
   * Subscribes to `${this.el.id}:${op}` for each key in `handlers`. The hook
   * receives only events targeted at its element id, so multiple charts on
   * the same page do not cross-talk.
   *
   * Server side, emit these via `D3Ex.Live.set_data/3` etc., or `push_event`
   * directly for custom operations.
   *
   * @param {object} handlers Map of op name → handler function. Handlers are
   *                          called as methods on `this`.
   */
  bindDataEvents(handlers) {
    const id = this.el.id;
    for (const op of Object.keys(handlers)) {
      this.handleEvent(`${id}:${op}`, (payload) => handlers[op].call(this, payload));
    }
  },

  /** Stop any d3 force simulations and clear throttle timers. */
  cleanup() {
    if (this.simulation) this.simulation.stop();
    if (this.throttleTimers) {
      Object.values(this.throttleTimers).forEach(clearTimeout);
    }
  },
};

/**
 * Factory that builds a LiveView hook on top of the D3Ex lifecycle.
 *
 * Handles the boilerplate every D3 hook needs: D3 readiness check, config
 * parsing into `this.config`, `data-events` parsing into `this.events`,
 * id-scoped data event subscription, and cleanup on destroy.
 *
 * Spread the result into your hook object and add component-specific methods
 * (initChart, renderChart, etc.) alongside it.
 *
 * @param {object}   opts
 * @param {function} opts.onMount   Called after `this.config` is parsed. Read
 *                                  initial data (`this.getData()` etc.) and
 *                                  initialize the visualization. `this` is the
 *                                  hook.
 * @param {function} [opts.onUpdated] Called from LiveView `updated()`. Use for
 *                                    scalar `data-*` attribute changes (e.g.
 *                                    selection). Bulk data should flow through
 *                                    `events`.
 * @param {function} [opts.onDestroy] Extra teardown. `this.cleanup()` runs
 *                                    automatically afterwards.
 * @param {object}   [opts.events]   Map of op → `this`-bound handler called
 *                                   when `${this.el.id}:${op}` fires.
 *
 * @example
 *   export const D3PieChart = {
 *     ...createD3Hook({
 *       onMount() {
 *         this.data = this.getData();
 *         this.initChart();
 *       },
 *       events: {
 *         set_data({ data }) { this.data = data; this.renderChart(); },
 *       },
 *     }),
 *     initChart() { ... },
 *     renderChart() { ... },
 *   };
 */
export const createD3Hook = ({ onMount, onUpdated, onDestroy, events } = {}) => ({
  ...D3Hook,

  mounted() {
    if (!window.d3) {
      console.error('D3.js is not loaded. Please include D3.js in your application.');
      return;
    }

    this.config = this.getConfig();
    this.events = this.getEvents();
    onMount?.call(this);
    if (events) this.bindDataEvents(events);
  },

  updated() {
    onUpdated?.call(this);
  },

  destroyed() {
    onDestroy?.call(this);
    this.cleanup();
  },
});

export default { D3Hook, createD3Hook };
