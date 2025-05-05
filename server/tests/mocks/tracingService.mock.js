/**
 * 分布式追踪服务模拟
 */
const { v4: uuidv4 } = require('uuid');
const { EventEmitter } = require('events');

class TraceContext {
  constructor(options = {}) {
    this.traceId = options.traceId || uuidv4();
    this.rootSpanId = options.rootSpanId || null;
    this.parentSpanId = options.parentSpanId || null;
    this.startTime = Date.now();
    this.endTime = null;
    this.completed = false;
    this.tags = options.tags || {};
    this.spans = new Map();
    this.activeSpan = null;
  }

  createSpan(name, options = {}) {
    const spanId = uuidv4();
    const parentId = this.activeSpan ? this.activeSpan.id : null;

    const span = {
      id: spanId,
      name,
      traceId: this.traceId,
      parentId,
      startTime: Date.now(),
      endTime: null,
      duration: null,
      status: 'active',
      tags: { ...options.tags },
      events: []
    };

    this.spans.set(spanId, span);
    this.activeSpan = span;

    return span;
  }

  endSpan(spanId, options = {}) {
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    span.endTime = Date.now();
    span.duration = span.endTime - span.startTime;
    span.status = 'completed';

    if (options && options.tags) {
      Object.assign(span.tags, options.tags);
    }

    if (this.activeSpan && this.activeSpan.id === spanId) {
      // 找到父span作为新的活动span
      const parentSpan = Array.from(this.spans.values()).find(s => s.id === span.parentId && s.status === 'active');
      this.activeSpan = parentSpan || null;
    }

    return span;
  }

  addSpanEvent(spanId, name, attributes = {}) {
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    const event = {
      name,
      timestamp: Date.now(),
      attributes
    };

    span.events.push(event);

    return event;
  }

  setSpanTag(spanId, key, value) {
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    span.tags[key] = value;

    return span;
  }

  setSpanStatus(spanId, status, message) {
    const span = this.spans.get(spanId);

    if (!span) {
      return null;
    }

    span.status = status;

    if (message) {
      span.tags.statusMessage = message;
    }

    return span;
  }

  complete() {
    // 结束所有活动span
    for (const [spanId, span] of this.spans.entries()) {
      if (span.status === 'active') {
        this.endSpan(spanId);
      }
    }

    this.endTime = Date.now();
    this.completed = true;

    return this;
  }

  getData() {
    return {
      traceId: this.traceId,
      rootSpanId: this.rootSpanId || (this.spans.size > 0 ? Array.from(this.spans.values())[0].id : null),
      parentSpanId: this.parentSpanId,
      startTime: this.startTime,
      endTime: this.endTime,
      duration: this.endTime ? this.endTime - this.startTime : null,
      completed: this.completed,
      tags: this.tags,
      spans: Array.from(this.spans.values())
    };
  }
}

class TracingService extends EventEmitter {
  constructor(config = {}) {
    super();

    this.config = {
      enabled: true,
      distributed: false,
      samplingRate: 1.0,
      headers: {
        traceId: 'x-trace-id',
        spanId: 'x-span-id',
        parentSpanId: 'x-parent-span-id'
      },
      exporters: {
        log: { enabled: false },
        zipkin: { enabled: false },
        jaeger: { enabled: false }
      },
      ...config
    };

    this.initialized = false;
    this.activeTraces = new Map();
    this.completedTraces = [];
  }

  async initialize() {
    if (this.initialized) {
      return;
    }

    this.initialized = true;
    return true;
  }

  async close() {
    this.initialized = false;
    return true;
  }

  createTrace(options = {}) {
    if (!this.initialized) {
      throw new Error('分布式追踪服务未初始化');
    }

    const trace = new TraceContext(options);
    this.activeTraces.set(trace.traceId, trace);

    return trace;
  }

  getTrace(traceId) {
    return this.activeTraces.get(traceId) || null;
  }

  completeTrace(traceId) {
    const trace = this.activeTraces.get(traceId);

    if (!trace) {
      return null;
    }

    trace.complete();
    this.activeTraces.delete(traceId);
    this.completedTraces.push(trace);

    return trace;
  }

  extractTraceContext(req) {
    if (!this.config.distributed) {
      return {};
    }

    const traceId = req.get(this.config.headers.traceId);
    const spanId = req.get(this.config.headers.spanId);
    const parentSpanId = req.get(this.config.headers.parentSpanId);

    if (!traceId) {
      return {};
    }

    return {
      traceId,
      rootSpanId: spanId,
      parentSpanId,
      tags: {
        'http.method': req.method,
        'http.url': req.originalUrl,
        'http.host': req.get('host'),
        'http.user_agent': req.get('user-agent')
      }
    };
  }

  injectTraceContext(headers, trace, spanId) {
    if (!this.config.distributed) {
      return headers;
    }

    const newHeaders = { ...headers };
    newHeaders[this.config.headers.traceId] = trace.traceId;
    newHeaders[this.config.headers.spanId] = spanId;

    if (trace.rootSpanId && trace.rootSpanId !== spanId) {
      newHeaders[this.config.headers.parentSpanId] = trace.rootSpanId;
    }

    return newHeaders;
  }

  getTracingStats() {
    return {
      traces: {
        active: this.activeTraces.size,
        completed: this.completedTraces.length,
        created: this.activeTraces.size + this.completedTraces.length,
        sampled: this.activeTraces.size + this.completedTraces.length
      }
    };
  }
}

// 创建实例
const tracingService = new TracingService();

module.exports = {
  TracingService,
  TraceContext,
  tracingService
};
